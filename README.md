## Initial Project Steps and Baseline Simulation

### Step 1: Code Review
The project began with a thorough review of the `LebwohlLasher.py` script to understand its core functionality and the computational model it implements. This initial step was crucial for identifying key areas where performance optimizations could be applied without altering the scientific accuracy of the simulations.

### Step 2: Baseline Simulation
To establish a baseline for performance, the following command was executed:
```bash
python3 LebwohlLasher.py 50 50 0.5 0
```

This simulation provided initial performance metrics:
- Size: 50
- Steps: 50
- Reduced Temperature (T*): 0.500
- Order: 0.281
- Time: 2.505193 seconds
These metrics serve as a reference point for assessing the impact of subsequent optimizations.

### Step 3: Profiling the Code
Profiling was performed to identify performance bottlenecks using the command:
```bash
python3 -m cProfile -o prof.txt LebwohlLasher.py 50 50 0.5 0
```
After generating the profiling data, I used the following commands in a Python interactive session to sort and analyze the top time-consuming functions:

```python
import pstats
p = pstats.Stats('prof.txt')
p.sort_stats('time').print_stats(10)
```

### Profiling Results
The profiling generated a detailed report, captured in `prof.txt`, summarizing the function calls and their execution times. Here are the top findings from the analysis:

- **Total Function Calls**: 1,463,687 (1,448,998 primitive calls) over 3.282 seconds.
- **Top Time-consuming Functions**:
  - `one_energy`: Called 377,500 times, taking 1.777 seconds. This function calculates the energy of a single cell and is the most significant time consumer.
  - `get_order`: Executed 51 times, consuming 0.602 seconds. It calculates the order parameter of the lattice.
  - `MC_step`: Invoked 50 times, with a total time of 0.233 seconds. This function performs one Monte Carlo step.

### Step 4: Applying Numba Optimization

Given the profiling results indicating that the `one_energy` function was a significant bottleneck, I decided to apply Numba's Just-In-Time (JIT) compilation to optimize it. Numba allows Python functions to be compiled to machine code, dramatically improving execution speed, especially in computationally intensive loops.

### Creating the Optimized Script
An optimized version of the original `LebwohlLasher.py` script was developed to enhance performance using Numba's Just-In-Time (JIT) compilation. This optimized script is named `LebwohlLasher_optimized_v1.py`.

**Creating the Optimized File:**

A new file was created and edited to include the optimizations:

```bash
touch LebwohlLasher_optimized_v1.py
nano LebwohlLasher_optimized_v1.py
```
#### Implementation
I added the `@numba.jit(nopython=True)` decorator to the `one_energy` function, transforming it from a standard Python functi>
```python
import numba

@numba.jit(nopython=True)
def one_energy(arr, ix, iy, nmax):
    # Function body remains unchanged
```

### Running the Simulations

**Original Simulation:**

```bash
python LebwohlLasher.py 50 50 0.5 0
# Output: Size: 50, Steps: 50, T*: 0.500: Order: 0.295, Time: 2.494044 seconds
```

**Optimized Simulation (with Numba):**

```bash
python LebwohlLasher_optimized_v1.py 50 50 0.5 0
# Output: Size: 50, Steps: 50, T*: 0.500: Order: 0.296, Time: 0.983887 seconds
```
### Performance Comparison

The introduction of Numba optimizations in `LebwohlLasher_optimized_v1.py` resulted in a substantial reduction in execution time. The details and results of running both the original and optimized simulations are documented for reference.

**Comparing Output:**

To ensure the integrity of the simulation's output remained unaffected, the results from both versions were compared:

```bash
python LebwohlLasher.py 50 50 0.5 0 > output_original.txt
python LebwohlLasher_optimized_v1.py 50 50 0.5 0 > output_optimized.txt
diff output_original.txt output_optimized.txt
```

The differences observed in the order parameter are within the expected range due to the stochastic nature of Monte Carlo simulations, confirming the optimization's effectiveness without compromising accuracy.


## step 5: Sequential Sampling Optimization

I explored an optimization by switching from random to sequential sampling in the Monte Carlo steps, aiming to improve computational efficiency and potentially affect the simulation's statistical properties.
### Code Modifications

The key modification involved replacing the random selection of lattice sites with a systematic, sequential approach during the Monte Carlo steps. Below are the specific changes made to the `MC_step` function in `LebwohlLasher_sequential.py`:

**Original Random Sampling Approach (Removed):**
```python
# Original code for random selection of lattice sites (REMOVED)
xran = np.random.randint(0, high=nmax, size=(nmax, nmax))
yran = np.random.randint(0, high=nmax, size=(nmax, nmax))
for i in range(nmax):
    for j in range(nmax):
        ix = xran[i, j]
        iy = yran[i, j]
        # Further logic for angle change and energy calculation...
```

**New Sequential Sampling Approach (Added):**
```python
# New approach using sequential sampling (ADDED)
for ix in range(nmax):
    for iy in range(nmax):
        ang = np.random.normal(scale=scale)
        en0 = one_energy(arr, ix, iy, nmax)
        arr[ix, iy] += ang
        en1 = one_energy(arr, ix, iy, nmax)
        if en1 <= en0:
            accept += 1
        else:
            boltz = np.exp(-(en1 - en0) / Ts)
            if boltz >= np.random.uniform(0.0, 1.0):
                accept += 1
            else:
                arr[ix, iy] -= ang  # Revert if not accepted
```
**Comments on the Change:**
- The original random sampling method involved generating entire matrices for `ix` and `iy` coordinates and then iterating over these matrices to select lattice sites randomly.
- The new method systematically iterates through each lattice site in order, simplifying the code and potentially improving cache efficiency. This sequential approach retains randomness in the angle changes while systematically exploring the lattice.

### Running the Optimized Simulation

To run the simulation with sequential sampling, use the following command:

```bash
python LebwohlLasher_sequential.py 50 50 0.5 0
```
## diff Output
```bash
diff output_original.txt output_sequential.txt
```
The output from the diff command indicates a difference between the results produced by the original script and the sequential sampling script. Specifically:

Original Script Output: The order parameter is 0.306, and the execution time is 2.661728 seconds.
Sequential Sampling Script Output: The order parameter is 0.371, and the execution time is 2.487066 seconds.


### step 6: Cython Optimization

- Focused on optimizing the `one_energy` function.
- Created a Cython version (`one_energy.pyx`) to leverage C-level performance enhancements.

### Code Snippets

**one_energy.pyx:**
```cython
# Import the C library for cos function
from libc.math cimport cos

cpdef double one_energy(double[:, :] arr, int ix, int iy, int nmax):
    ...
```

**setup.py for compiling Cython code:**
```python
from setuptools import setup
from Cython.Build import cythonize

setup(ext_modules=cythonize("one_energy.pyx"))
```

### Command Line for Compilation
```bash
python setup.py build_ext --inplace
```

##  Creating an Optimized Script

- Generated `LebwohlLasher_optimized_v2.py` to utilize the Cython-optimized `one_energy` function.

### Code Modifications

**In LebwohlLasher_optimized_v2.py:**
```python
from one_energy import one_energy  # Use the Cython-optimized function
```

## Step 3: Running the Optimized Simulation

- Executed the optimized script with specified parameters to evaluate performance improvements.

### Command Line Execution
```bash
python3 LebwohlLasher_optimized_v2.py 50 50 0.5 0
```

## Step 4: Comparison with Original Script

- To assess the effectiveness of optimizations, compared the performance and output of the optimized script against the original.

### Generating Output Files for Comparison

**Original Script Output:**
```bash
python3 LebwohlLasher.py 50 50 0.5 0 > output_original.txt
```

**Optimized Script Output:**
```bash
python3 LebwohlLasher_optimized_v2.py 50 50 0.5 0 > output_optimized_v2.txt
```

### Command Line for Differences
```bash
diff output_original.txt output_optimized_v2.txt
```
Original Script (LebwohlLasher.py):

Execution Time: 2.612235 seconds
Order Parameter: 0.283
Optimized Script (LebwohlLasher_optimized_v2.py):

Execution Time: 2.634999 seconds
Order Parameter: 0.349

