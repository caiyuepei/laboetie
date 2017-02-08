! Here is a smolu with diffusion + electrostatic part only
! The objective is to end up in a situation where equilibrium
! distribution of solutes (c_plus and c_minus) is found,
! ie in which the total flux of solutes is zero.

subroutine just_eq_smolu
    use precision_kinds
    use system, only: D_plus, D_minus, node,&
        D_equil, time, fluid, phi, c_plus, c_minus,&
        rho_0=>rho_ch, sigma, pbc, supercell
    use constants, only: x, y, z
    use mod_lbmodel, only: lbm
    use myAllocations
    implicit none
    integer(i2b) :: iter, max_iter
    real(dp), dimension(:,:,:), allocatable :: flux_site_plus, flux_site_minus
    integer(i2b) :: i, j, k, ip, jp, kp, l ! dummy
    real(dp) :: exp_dphi, exp_min_dphi ! Exp[phi site1 - phi site 2] and 1/Exp
    real(dp) :: flux_link_plus, flux_link_minus
    real(dp) :: tot_diff_plus, tot_diff_minus ! total flux of + and - solutes init at high values
    real(dp) :: eD_plus, eD_minus ! effective D_plus and D_minus
    real(dp), parameter :: convergence_criteria = 5.e-6
    call allocateReal3D( flux_site_plus)
    call allocateReal3D( flux_site_minus)
    ! init
    !tot_diff_plus = huge(1.0_dp)
    !tot_diff_minus = huge(1.0_dp)
    tot_diff_plus = convergence_criteria
    tot_diff_minus = convergence_criteria 
    ! diffusion coefficients of solutes are read in input file.
    ! if we're in the first steps of equilibration, it speeds up convergence
    ! to use a smaller diffusion coefficient.
    ! i think there is a bug in C code here,
    ! especially considering the high amount of magic numbers and +- convention for time.
    if( time > 0 .or. time<-D_equil) then
        stop 'in just_eq_smolu.f90. Should be accessed in equilibration steps only'
    else if( time < -D_equil+100) then ! 100 first steps
        eD_plus = 0.1_dp*D_plus
        eD_minus = 0.1_dp*D_minus
        max_iter = 10
    else if( time < -D_equil +500) then
        eD_plus = D_plus
        eD_minus = D_minus
        max_iter = 1
    else
        if( D_plus < 0.03_dp) then
            eD_plus = 0.03_dp ! too a small D is not effective for this step. no physic is associated to the "dynamic" of this step.
        else
            eD_plus = D_plus
        end if
    if( D_minus < 0.03_dp) then
      eD_minus = 0.03_dp
    else
      eD_minus = D_minus
    end if
    max_iter = 1
  end if
  print*,'D_plus, D_minus, max_iter ',eD_plus,eD_minus,max_iter

  ! init convergence iterations
  iter = 0
  !print*, 'max_iter = ', max_iter, 'iter =', iter
  !print*, 'tot_diff_minus+tot_diff_plus = ', tot_diff_minus + tot_diff_plus
  do while( tot_diff_minus + tot_diff_plus > convergence_criteria .and. iter < max_iter )

    ! flux_site_plus or minus is what makes the system evoluate.
    flux_site_plus = 0.0_dp
    flux_site_minus = 0.0_dp
    !print*, 'WE HAVE ARRIVED JUST BEFORE THE LOOP'
    ! for all sites
    do i= supercell%geometry%dimensions%indiceMin(x), supercell%geometry%dimensions%indiceMax(x) 
      do j= supercell%geometry%dimensions%indiceMin(y), supercell%geometry%dimensions%indiceMax(y) ! ADE : There was an error for j and k. The counter started at Max instead of Min. Copy and paste mistake
        do k= supercell%geometry%dimensions%indiceMin(z), supercell%geometry%dimensions%indiceMax(z)
          !print*, '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
          !print*, 'WE ARE IN THE LOOP'
 
          ! here one could add a if(node(i,j,k)%nature==solid)cycle ! but things get hard to read

          ! and all neighbours of this site
          do l= lbm%lmin+1, lbm%lmax, 2 ! at once flux in both directions ! l=1 corresponds to no velocity ie flux toward itself ie delta(l)=0
          !print*, '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
          !print*, 'WE ARE IN THE LOOP2'

            ! periodic boundary conditions to neighbours
            ip= pbc( i+ lbm%vel(l)%coo(x) ,x)
            jp= pbc( j+ lbm%vel(l)%coo(y) ,y)
            kp= pbc( k+ lbm%vel(l)%coo(z) ,z)

            !print*, '**********************************************'
            !print*, 'Index ip = ', ip, ' Index i = ', i, 'Index j = ', j, 'Index k = ', k
            !print*, '**********************************************'

            ! continue for fluid-fluid flux only
            OPEN( 165, FILE="output/VraiFaux.dat" )
            WRITE(165,*) node(i,j,k)%nature == fluid, node(ip,jp,kp)%nature == fluid, node(i,j,k)%nature, node(ip,jp,kp)%nature
            !print*,' LOGICAL = ', node(i,j,k)%nature == fluid
            if( node(i,j,k)%nature == fluid .and. node(ip,jp,kp)%nature == fluid) then
            !print*, '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
            !print*, 'WE ARE IN THE LOOP3'

              ! compute the difference in potential between sites i,j,k and ip,jp,kp
              exp_dphi = exp( phi(ip,jp,kp) - phi(i,j,k) ) ! be carefull to sign
              exp_min_dphi = 1.0_dp / exp_dphi ! dummy

              ! flux due to electrostatic and density gradients inside link i,j,k <-> ip,jp,kp
              flux_link_plus  = 0.5_dp * (1.0_dp+ exp_min_dphi)*( c_plus(ip,jp,kp) * exp_dphi     - c_plus (i,j,k) )
              flux_link_plus = flux_link_plus * eD_plus / lbm%vel(l)%delta
              flux_link_minus = 0.5_dp * (1.0_dp+ exp_dphi    )*( c_minus(ip,jp,kp) * exp_min_dphi - c_minus(i,j,k) )
              !print*, '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
              !print*, 'flux_link_plus1 =', flux_link_plus 
              !print*, '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
              flux_link_minus = flux_link_minus * eD_minus / lbm%vel(l)%delta
              !print*, '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
              !print*, 'flux_link_plus2 =', flux_link_plus 
              !print*, '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'

              ! update flux on each site accordingly to flux inside link involving site
              flux_site_plus(i,j,k) = flux_site_plus(i,j,k) + flux_link_plus
              flux_site_minus(i,j,k) = flux_site_minus(i,j,k) + flux_link_minus
              flux_site_plus(ip,jp,kp) = flux_site_plus(ip,jp,kp) - flux_link_plus
              flux_site_minus(ip,jp,kp) = flux_site_minus(ip,jp,kp) - flux_link_minus
            end if
          end do

        end do
      end do
    end do

    ! no concentration should be lost, just transfered, ie sum of flux over all sites should be 0.
    if( abs(sum(flux_site_plus)) > 1.e-12 .or. abs(sum(flux_site_minus)) > 1.e-12) then
      print*,'abs(sum(flux_site_plus))=',abs(sum(flux_site_plus))
      print*,'abs(sum(flux_site_minus))=',abs(sum(flux_site_minus))
      stop 'the sum of all flux does not add up. problem in just_eq_smolu.f90'
    end if

    !print*, '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
    !print*, '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
    !print*, 'flux_site_plus =', flux_site_plus 
    !print*, '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
    !print*, '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
    ! update concentrations (smolushowski part)
    where(node%nature==fluid)
      c_plus = c_plus + flux_site_plus
      c_minus = c_minus + flux_site_minus
    end where
    WRITE(165,*) flux_site_minus
    CLOSE(165)


    ! compute the total flux in this equilibration step one wants to minimize.
    if( sigma/=0 .and. eD_plus/=0.0_dp .and. eD_minus/=0.0_dp ) then
      ! the sum of all flux
      tot_diff_plus  = sqrt(sum(flux_site_plus**2,mask=(node%nature==fluid))) &
          / count(node%nature==fluid) / (0.5_dp*rho_0*eD_plus ) / sigma ! 1st denominator is the number of fluid nodes)
      tot_diff_minus = sqrt(sum(flux_site_minus**2,mask=(node%nature==fluid))) &
          / count(node%nature==fluid) / (0.5_dp*rho_0*eD_minus) / sigma ! norm2 is the Fortran intrinsic for euclidean norm
!      print*,'DIFF_plus =',tot_diff_plus,' DIFF_minus =',tot_diff_minus
    end if

    ! increment iteration
    iter = iter +1

  end do ! while loop about convergence on tot_diff_minus+tot_diff_plus
end subroutine just_eq_smolu
