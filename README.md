# Fast tangent and secant approximation

* Input range `(-π/4, π/4)` expressed as binary angle measurement `(0xe000, 0xffff] U [0x0000, 0x2000)`
* 512 byte lookup table (256b each for tangent and secant)
* Q18 Fixed-point result accurate within 2 bits

## Table generation

[gen_values.py](gen_values.py)

* Use [lolremez Remez Method library](https://github.com/samhocevar/lolremez) to generate polynomial of degree 2 for 32 divisions of input range
* Incorporate fixed-point shift and base offset into constant term

[gen_array.py](gen_array.py)

* Pack coefficients into 8 bytes per division
* Output C++ header with array and constants

# Full-range arctan2 using CORDIC

* Output angle expressed as binary angle measurement `[0x0, 0xffff]`
* 10 iterations of CORDIC vectoring mode to find angle
* Angle accurate to within 5 bits (`32 / 0x10000` approx. `0.0031 rad`)
* Hypotenuse optional
	- Calculated by dividing result `x` by gain $\prod_{i=0}^{9} \sqrt{1 + 2^{-2 \cdot i}} \approx 1.64676$

# Branchless ARMv4 implementation

Tangent

* 16 ALU operations
* 1 multiply and 1 multiply-accumulate operation
* 2 load operations
* Completes in 30 cycles including return (on system with 1 cycle word read)

Secant

* Same polynomial evaluation core as tangent
* 3 cycles to adjust input followed by tangent core, 33 cycles

Arctangent

* 89 cycles including return, all ALU
	- 12 cycles for input adjustment to range `(-π/4, π/4)`
	- 75 cycles for 10 CORDIC iterations
	- 2 cycles for negative angle adjustment

* 3 cycles for Q8 hypotenuse gain adjustment (if used)
	- See [header](arm-test/trig_approx.hpp) for hypotenuse use and gain adjustment

[ARMv4 source including table](arm-test/trig_approx.arm.s)
