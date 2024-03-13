from setuptools import setup
from Cython.Build import cythonize

setup(
    name='LebwohlLasherCython',
    ext_modules=cythonize("one_energy.pyx"),
)

