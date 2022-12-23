#define _USE_MATH_INCLUDES
#include <cmath>

#include <cstdint>
#include <cstddef>
#include <cstdio>
#include <cassert>

#include <limits>
#include <array>

#include <rapidcheck.h>

#include "tan_approx.hpp"

int main(int argc, char** argv)
{
	for (int32_t x = 0x0; x < 0x2000; x++) {
		auto run_test = [](uint32_t x) {
			auto calculated = int32_t(tan(float(x) / 0x10000 * 2 * M_PI) * (1 << 18));
			auto approximated = tan_approx(x);
			if (abs(calculated - approximated) > 2) {
				fprintf(stderr, "failed: %x calc %d appr %d\n", x, calculated, approximated);
				exit(-1);
			}
		};

		run_test(x);
#if 0
		if (0 < x) {
			run_test(0x10000 - x);
		}
#endif
	}

	fprintf(stderr, "passed\n");
	return 0;

	rc::check("tangent approximation",
		[]() {
			auto run_test = [](uint32_t x) {
				auto calculated = int32_t(tan(float(x) / 0x10000 * 2 * M_PI) * (1 << 18));
				auto approximated = tan_approx(x);

				RC_ASSERT(abs(calculated - approximated) <= 2);
			};

			auto x = *rc::gen::inRange(0, 0x2000);
			run_test(x);
			if (0 < x) {
				run_test(0x10000 - x);
			}
		});

	return 0;
}
