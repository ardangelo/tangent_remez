#define _USE_MATH_INCLUDES
#include <cmath>
#include <cstdio>

#include <rapidcheck.h>

#include "tan_approx.hpp"

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
			fprintf(stderr, "Failed angle 0x%x\n", x);
			return -1;
		}
	}

	// Test all angles in range (-pi/4, 0)
	for (int32_t x = 0xe0001; x < 0x10000; x++) {
		if (!test_angle(x)) {
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
		RC_ASSERT(test_angle(x));
		if (0 < x) {
			RC_ASSERT(test_angle(0x10000 - x));
		}
	});

	return 0;
}
