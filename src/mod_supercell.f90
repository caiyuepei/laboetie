! where one defines everything related to the supercell. Not the fluid or anything else. For now, does not contain
! its most evident constants lx ly and lz which are the supercell sizes (in LB units). TODO
MODULE supercell
  use precision_kinds
  implicit none
  private ! everything private by default
  public :: is_interfacial,&
            where_is_it_fluid_and_interfacial,&
            check_that_at_least_one_node_is_fluid,&
            check_that_all_nodes_are_wether_fluid_or_solid,&
            define_periodic_boundary_conditions
  logical, allocatable, dimension(:,:,:) :: is_interfacial ! true if the node is fluid .AND. at an interface
  contains

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

SUBROUTINE where_is_it_fluid_and_interfacial
  use system, only: lx, ly, lz, inside, fluid, normal
  implicit none
  allocate( is_interfacial(lx,ly,lz) )
  where(norm2(normal,4)/=0.0_dp .and. inside==fluid) ! where the norm of normal(i,j,k,:)
    is_interfacial = .true.
  else where
    is_interfacial = .false.
  end where
END SUBROUTINE where_is_it_fluid_and_interfacial

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

SUBROUTINE check_that_at_least_one_node_is_fluid
  use system, only: inside, fluid
  implicit none
  if(count(inside==fluid)==0) stop 'subroutine check_that_at_least_one_node_is_fluid identified no fluid node. fatal error.'
END SUBROUTINE check_that_at_least_one_node_is_fluid

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

SUBROUTINE check_that_all_nodes_are_wether_fluid_or_solid
  use system, only: inside, fluid, solid, lx, ly, lz
  implicit none
  if((count(inside==fluid)+count(inside==solid)) /= lx*ly*lz) stop &
       'subroutine check_that_all_nodes_are_wether_fluid_or_solidsome identified some nodes as neither solid nor fluid.'
END SUBROUTINE check_that_all_nodes_are_wether_fluid_or_solid

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

SUBROUTINE define_periodic_boundary_conditions
  use system, only: plusx, plusy, plusz, lx, ly, lz
  implicit none
  integer(i2b) :: i
  allocate( plusx(0:lx+1), plusy(0:ly+1), plusz(0:lz+1) )
  do concurrent (i = 1: lx)
    plusx(i) = i
  end do
  do concurrent (i = 1: ly)
    plusy(i) = i
  end do
  do concurrent (i = 1: lz)
    plusz(i) = i
  end do
  plusx(0) = lx
  plusy(0) = ly
  plusz(0) = lz
  plusx(lx+1) = 1
  plusy(ly+1) = 1
  plusz(lz+1) = 1
END SUBROUTINE define_periodic_boundary_conditions

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

END MODULE supercell
