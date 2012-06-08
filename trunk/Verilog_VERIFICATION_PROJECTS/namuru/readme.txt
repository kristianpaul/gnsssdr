Folders descriptions:

1) bat            - contains *.bat files to run icarus simulations under windows.
2) rtl            - Namuru correlator source code.
3) sci            - simple SciLab script to check carrier NCOs spectrum.
4) sh             - the same as bat-folder but for Linux.
5) test           - testbenches for icarus to check correlator submodules.
6) test_verilator - testbenches for verilator. Each correlator submodule is checked. Also main module is checked with control program written in C for hw (cosimulation of verilog and C is performed).
7) vpi            - main correlator module test with icarus. VPI is used to call external control program written in C.

IMPORTANT: Currently working version of test that checks Namuru-main module is placed in the folder "test_verilator\gps_baseband_16bit_async_mem_bus\". Tests in folders "vpi" and "test_verilator\simlpified_gps_baseband\" may be currently incorrect and they are left just as an examlpe.

IMPORTANT2: It's important to have apropriate signal record to run simulation in folder "test_verilator\gps_baseband_16bit_async_mem_bus\". Also file_paths can require corrections!