# Importing the necessary C library for the cos function
from libc.math cimport cos

# Defining the Cython function with static types for parameters and variables
cpdef double one_energy(double[:, :] arr, int ix, int iy, int nmax):
    cdef:
        # Variable declarations with types for efficiency
        int ixp, ixm, iyp, iym
        double en = 0.0
        double ang

    # Calculating indices for the periodic boundary conditions
    ixp = (ix + 1) % nmax
    ixm = (ix - 1) % nmax
    iyp = (iy + 1) % nmax
    iym = (iy - 1) % nmax

    # Energy calculation considering neighboring interactions
    # Calculating the angle difference and energy contribution for each neighbor
    ang = arr[ix, iy] - arr[ixp, iy]
    en += 0.5 * (1.0 - 3.0 * cos(ang) ** 2)

    ang = arr[ix, iy] - arr[ixm, iy]
    en += 0.5 * (1.0 - 3.0 * cos(ang) ** 2)

    ang = arr[ix, iy] - arr[ix, iyp]
    en += 0.5 * (1.0 - 3.0 * cos(ang) ** 2)

    ang = arr[ix, iy] - arr[ix, iym]
    en += 0.5 * (1.0 - 3.0 * cos(ang) ** 2)

    # Returning the calculated energy for the cell
    return en

