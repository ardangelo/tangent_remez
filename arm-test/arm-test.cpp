#define _USE_MATH_INCLUDES
#include <cmath>
#include <cstdint>
#ifndef M_PI
#define M_PI 3.141592653589793238462643
#endif

#include "nocash_printf.hpp"

#include "trig_approx.hpp"

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

static auto test_sec_angle(uint32_t x)
{
	// Real Q18 value for 1/cos(x)
	auto calculated = int32_t(round((1 << 18) / cos(float(x) / 0x10000 * 2 * M_PI)));

	// Q18 approximation for 1/cos(x)
	auto approximated = sec_approx(x);

	// Should be accurate to within 2 bits
	return abs(calculated - approximated) <= 2;
}

static auto test_atan2(int32_t x, int32_t y)
{
	auto [angle, gained_hyp] = cordic_atan2_hyp(x, y);
	auto hyp = adj_cordic_hyp(gained_hyp);

	auto actual_angle = int32_t(round(atan2(y, x) / (2 * M_PI) * 0x10000));
	if (actual_angle < 0) { actual_angle += 0x10000; }
	auto fpsq = [](int32_t x) {
		auto xf = float(x) / (1 << 16);
		return xf * xf;
	};
	auto ahf = sqrt(fpsq(x) + fpsq(y)) * (1 << 16);
	auto actual_hyp = int32_t(round(ahf));

	if (abs(actual_angle - angle) > 32) {
		set_bg_color(0x001f);
		nocash_printf("Failed atan2(%d / %d) angle: actual %d appr %d",
			y, x, actual_angle, angle);
		nocash_break(true);
	}

	if (float(abs(actual_hyp - hyp)) / actual_hyp > 0.01) {
		set_bg_color(0x001f);
		nocash_printf("Failed atan2(%d / %d) hyp: actual %d appr %d",
			y, x, actual_hyp, hyp);
		nocash_break(true);
	}
};

int main(int argc, char** argv)
{
	// Test all angles in range [0, pi/4)
	for (int32_t x = 0x0; x < 0x2000; x++) {
		if (!test_tan_angle(x) || !test_sec_angle(x)) {
			set_bg_color(0x001f);
			nocash_printf("Failed angle 0x%x", x);
			nocash_break(true);
		}
	}

	// Test all angles in range (-pi/4, 0)
	for (int32_t x = 0xe001; x < 0x10000; x++) {
		if (!test_tan_angle(x) || !test_sec_angle(x)) {
			set_bg_color(0x001f);
			nocash_printf("Failed angle 0x%x\n", x);
			nocash_break(true);
		}
	}

	// Basic atan2 tests
	test_atan2(50, -30);
	test_atan2(50, 30);
	test_atan2(30, 50);
	test_atan2(-30, 50);
	test_atan2(-50, 30);
	test_atan2(-50, -30);
	test_atan2(-30, -50);
	test_atan2(30, -50);

	set_bg_color(0x03e0);
	nocash_printf("Passed all angles in range (0xe000, 0xffff], [0x0000, 0x2000)");

	nocash_printf("Running CORDIC atan2 test, will take a while...");

	for (int32_t x = 0x100; x < 0x1000; x += 0x101) {
		for (int32_t y = 0x10000; y < 0x100000; y += 0x101) {
			test_atan2(x, y);
			test_atan2(-x, y);
			test_atan2(x, -y);
			test_atan2(-x, -y);
		}
	}

	nocash_break(true);

	return 0;
}
