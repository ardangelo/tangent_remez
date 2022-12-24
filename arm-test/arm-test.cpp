#define _USE_MATH_INCLUDES
#include <cmath>
#include <cstdint>
#ifndef M_PI
#define M_PI 3.141592653589793238462643
#endif

#include "nocash_printf.hpp"

extern "C" {
	int32_t tan_approx(uint32_t x);
	int32_t icos_approx(uint32_t x);
} // extern "C"

static void set_bg_color(uint32_t rgb15)
{
	*(uint32_t volatile*)0x04000000 = 0x0403;
	for (uint32_t y = 0; y < 160; y++) {
		for (uint32_t x = 0; x < 240; x++) {
			((uint16_t volatile*)0x06000000)[x + y*240] = rgb15;
		}
	}
}

static auto test_tan_angle(uint32_t x)
{
	// Real Q18 value for tan(x)
	auto calculated = int32_t(round(tan(float(x) / 0x10000 * 2 * M_PI) * (1 << 18)));

	// Q18 approximation for tan(x)
	auto approximated = tan_approx(x);

	// Should be accurate to within 2 bits
	return abs(calculated - approximated) <= 2;
}

static auto test_icos_angle(uint32_t x)
{
	// Real Q18 value for 1/cos(x)
	auto calculated = int32_t(round((1 << 18) / cos(float(x) / 0x10000 * 2 * M_PI)));

	// Q18 approximation for 1/cos(x)
	auto approximated = icos_approx(x);

	// Should be accurate to within 2 bits
	return abs(calculated - approximated) <= 2;
}

int main(int argc, char** argv)
{
	// Test all angles in range [0, pi/4)
	for (int32_t x = 0x0; x < 0x2000; x++) {
		if (!test_tan_angle(x) || !test_icos_angle(x)) {
			set_bg_color(0x001f);
			nocash_printf("Failed angle 0x%x", x);
			nocash_break(true);
		}
	}

	// Test all angles in range (-pi/4, 0)
	for (int32_t x = 0xe001; x < 0x10000; x++) {
		if (!test_tan_angle(x) || !test_icos_angle(x)) {
			set_bg_color(0x001f);
			nocash_printf("Failed angle 0x%x\n", x);
			nocash_break(true);
		}
	}

	set_bg_color(0x03e0);
	nocash_printf("Passed all angles in range (0xe000, 0xffff], [0x0000, 0x2000)");
	nocash_break(true);

	return 0;
}
