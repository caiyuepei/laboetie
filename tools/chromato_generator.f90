PROGRAM chromato_generator

    IMPLICIT NONE

    INTEGER, PARAMETER :: nx=1, ny=50, nz=50, solid=1, liquid=0
    DOUBLE PRECISION :: r(3,max(nx,ny,nz)), d, dx, dy, dz
    DOUBLE PRECISION, PARAMETER :: rad=5., dia=2*rad
    INTEGER :: grid(nx,ny,nz), idisk, i, j, k, ndisk
    character :: arg


    CALL get_command_argument(1,arg)

    read(arg,*) ndisk

    call init_random_seed()

    CALL RANDOM_NUMBER(r)
    do i=1,ndisk
        r(:,i)=r(:,i)*[nx,ny,nz]+1
    end do

    if(nx==1) r(1,:)=1
    
    do i=1,ndisk
        do j=1,ndisk
            if( i==j) cycle
            do while( norm2(  r(:,i)-r(:,j)  ) <= dia )
                call random_number(r(:,j))
                if(nx==1) r(1,:)=1
            end do
        end do
    end do

    !do i=1,ndisk-1
    !    do j=i+1,ndisk
    !        print*, i,j,norm2(  r(:,i)-r(:,j))
    !    end do
    !end do

    grid = liquid

    DO idisk=1,ndisk
        DO i=1,nx
            DO j=1,ny
                DO k=1,nz

                    !
                    ! If node already written to file, then cycle
                    !
                    IF( grid(i,j,k) == solid ) CYCLE

                    dx= abs(i-r(1,idisk))
                    dy= abs(j-r(2,idisk))
                    dz= abs(k-r(3,idisk))
                    dx= min(dx,nx-dx)
                    dy= min(dy,ny-dy)
                    dz= min(dz,nz-dz)
                    d= sqrt(dx**2+dy**2+dz**2)
                    IF( d <= rad ) then
                        grid(i,j,k)=solid
                        PRINT*,i,j,k
                    end if
    
                END DO
            END DO
        END DO
    END DO




END PROGRAM



          subroutine init_random_seed()
            use iso_fortran_env, only: int64
            implicit none
            integer, allocatable :: seed(:)
            integer :: i, n, un, istat, dt(8), pid
            integer(int64) :: t
          
            call random_seed(size = n)
            allocate(seed(n))
            ! First try if the OS provides a random number generator
            open(newunit=un, file="/dev/urandom", access="stream", &
                 form="unformatted", action="read", status="old", iostat=istat)
            if (istat == 0) then
               read(un) seed
               close(un)
            else
               ! Fallback to XOR:ing the current time and pid. The PID is
               ! useful in case one launches multiple instances of the same
               ! program in parallel.
               call system_clock(t)
               if (t == 0) then
                  call date_and_time(values=dt)
                  t = (dt(1) - 1970) * 365_int64 * 24 * 60 * 60 * 1000 &
                       + dt(2) * 31_int64 * 24 * 60 * 60 * 1000 &
                       + dt(3) * 24_int64 * 60 * 60 * 1000 &
                       + dt(5) * 60 * 60 * 1000 &
                       + dt(6) * 60 * 1000 + dt(7) * 1000 &
                       + dt(8)
               end if
               pid = getpid()
               t = ieor(t, int(pid, kind(t)))
               do i = 1, n
                  seed(i) = lcg(t)
               end do
            end if
            call random_seed(put=seed)
          contains
            ! This simple PRNG might not be good enough for real work, but is
            ! sufficient for seeding a better PRNG.
            function lcg(s)
              integer :: lcg
              integer(int64) :: s
              if (s == 0) then
                 s = 104729
              else
                 s = mod(s, 4294967296_int64)
              end if
              s = mod(s * 279470273_int64, 4294967291_int64)
              lcg = int(mod(s, int(huge(0), int64)), kind(0))
            end function lcg
          end subroutine init_random_seed


