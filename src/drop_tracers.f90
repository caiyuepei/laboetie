! Here tracers are droped in the fluid. They may be charged or not. They evoluate in the
! equilibrated fluid and its solutes. They do not change the potential even if they
! have a charge. The idea is to follow them in order to get the velocity auto correlation
! function, while making them not to change the equilibrium properties of the system.
! Imagine a very small droplet of radioactive particles, so few they do not change
! anything to the system, but numerous enough to be followed and make statistics.

subroutine drop_tracers

  use precision_kinds, only: dp, i2b
  use system, only: tmom, tmax, elec_slope_x, elec_slope_y, elec_slope_z, D_tracer, z_tracer
  use populations, only: calc_n_momprop
  use moment_propagation, only: init, propagate, deallocate_propagated_quantity!, print_vacf, integrate_vacf!, not_yet_converged
  use input, only: input_dp

  implicit none
  integer(kind=i2b) :: it

  print*,'       step           VACF(x)                   VACF(y)                   VACF(z)'
  print*,'       ----------------------------------------------------------------------------------'

  ! read diffusion coefficient and charge of tracers in input file
  d_tracer = input_dp('D_tracer')
  z_tracer = input_dp('z_tracer')
  if(d_tracer < 0.0_dp) stop 'D_tracer <0. critical'

  ! include elec_slope_ in population n
  call calc_n_momprop

  ! turn the electric field off for the rest of mom_prop (included in n)
  elec_slope_x = 0.0_dp;
  elec_slope_y = 0.0_dp;
  elec_slope_z = 0.0_dp;

  ! add electrostatic potential computed by the SOR routine an external contribution
  ! elec_pot(singlx,ly,lz, ch, phi, phi2, inside, t, t_equil);
  ! call elec_pot

  call init ! init moment propagation

  ! propagate in time
  do it= 1, tmax-tmom
!  it=0
!  do while (not_yet_converged(it))
!   call elec_pot
    call propagate(it) ! propagate the propagated quantity
!    if( modulo(it,50000)==0 ) print_vacf
!    it = it + 1
  end do

  print*,

!  call integrate_vacf ! compute the integral over time of vacf in each direction
!  call print_vacf ! print vacf to file vacf.dat
  call deallocate_propagated_quantity

end subroutine drop_tracers
