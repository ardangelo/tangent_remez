#define _USE_MATH_INCLUDES
#include <cmath>
#ifndef M_PI
#define M_PI 3.141592653589793238462643
#endif

#include "tan_approx.hpp"
#include "nocash_printf.hpp"

static auto test_angle(uint32_t x)
{
	// Real Q18 value for tan(x)
	auto calculated = int32_t(tan(float(x) / 0x10000 * 2 * M_PI) * (1 << 18));

	// Q18 approximation for tan(x)
	auto approximated = tan_approx(x);

	// Should be accurate to within 2 bits
	return abs(calculated - approximated) <= 2;
}

int main(int argc, char** argv)
{
	// Test all angles in range [0, pi/4)
	for (int32_t x = 0x0; x < 0x2000; x++) {
		if (!test_angle(x)) {
			nocash_printf("Failed angle 0x%x", x);
			nocash_break(true);
		}
	}

	// Test all angles in range (-pi/4, 0)
	for (int32_t x = 0xe0001; x < 0x10000; x++) {
		if (!test_angle(x)) {
			nocash_printf("Failed angle 0x%x\n", x);
			nocash_break(true);
		}
	}

	nocash_printf("Passed all angles in range (0xe000, 0xffff], [0x0000, 0x2000)");
	nocash_break(true);

	return 0;
}
