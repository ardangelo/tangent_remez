#include <cmath>
#ifndef M_PI
#define M_PI 3.14159265359
#endif

#include "tan_approx.hpp"
#include "console.hpp"

static void run_test(uint32_t x)
{
	auto calculated = int32_t(tan(float(x) / 0x10000 * 2 * M_PI) * (1 << 18));
	auto approximated = tan_approx(x);
	if (abs(calculated - approximated) > 2) {
		nocash_printf("failed: %x calc %d appr %d", x, calculated, approximated);
		nocash_break(true);
	}
};

int main(int argc, char** argv)
{

	for (int32_t x = 0x0; x < 0x2000; x++) {
		run_test(x);
		if (0 < x) {
			run_test(0x10000 - x);
		}

		if (x % 0x100 == 0) {
			nocash_printf("completed %x", x);
		}
	}

	nocash_printf("passed all angles");
	nocash_break(true);

	return 0;
}