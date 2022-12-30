#define _USE_MATH_INCLUDES
#include <cmath>
#include <cstdio>

#include <rapidcheck.h>

#include "trig_approx.hpp"

static auto test_tan_angle(uint32_t x)
{
	// Real Q18 value for tan(x)
	auto calculated = int32_t(round(tan(float(x) / 0x10000 * 2 * M_PI) * (1 << 18)));

	// Q18 approximation for tan(x)
	auto approximated = tan_approx(x);

	// Should be accurate to within 2 bits
	return abs(calculated - approximated) <= 2;
}

static auto test_sec_angle(uint32_t x)
{
	// Real Q18 value for 1/cos(x)
	auto calculated = int32_t(round((1 << 18) / cos(float(x) / 0x10000 * 2 * M_PI)));

	// Q18 approximation for 1/cos(x)
	auto approximated = sec_approx(x);

	// Should be accurate to within 2 bits
	return abs(calculated - approximated) <= 2;
}

static auto test_cordic_atan2(int32_t y, int32_t x)
{
	auto calculated = int32_t(round(atan2(y, x) / (2 * M_PI) * 0x10000));
	auto approximated = cordic_atan2(y, x);
	fprintf(stderr, "%d %d\n", calculated, approximated);
	return abs(calculated - approximated) <= 128;
}

int main(int argc, char** argv)
{
	// Test all angles in range [0, pi/4)
	for (int32_t x = 0x0; x < 0x2000; x++) {
		if (!test_tan_angle(x) || !test_sec_angle(x)) {
			fprintf(stderr, "Failed angle 0x%x\n", x);
			return -1;
		}
	}

	// Test all angles in range (-pi/4, 0)
	for (int32_t x = 0xe0001; x < 0x10000; x++) {
		if (!test_tan_angle(x) || !test_sec_angle(x)) {
			fprintf(stderr, "Failed angle 0x%x\n", x);
			return -1;
		}
	}

	printf("Passed all angles in range (0xe000, 0xffff], [0x0000, 0x2000)\n");

	// Example test with rapidcheck
	rc::check("tangent approximation", []() {

		// Generate arbitrary angle
		auto x = *rc::gen::inRange(0, 0x2000);

		// Test positive and negative
		RC_ASSERT(test_tan_angle(x));
		if (0 < x) {
			RC_ASSERT(test_tan_angle(0x10000 - x));
		}
	});

		// Example test with rapidcheck
	rc::check("cordic atan2", []() {

		// Generate arbitrary coordinates
		auto x = *rc::gen::arbitrary<int16_t>() * (1 << 16);
		auto y = *rc::gen::arbitrary<int16_t>() * (1 << 16);

		RC_ASSERT(test_cordic_atan2(y, x));
	});

	return 0;
}
