#include "trig_approx.hpp"
#include "trig_array.gen.hpp"

#include <cstdio>
#include <tuple>

static_assert(values::fp == 18);
static_assert(values::width == 0x100);

int32_t _trig_approx(uint32_t x)
{
	x = (x < 0x8000) ? x : (0x10000 - x);

	auto data = values::data + 2 * (x / 0x100);
	x = x % 0x100;
	auto d0 = data[0];
	uint32_t t0 = d0 >> 16;
	d0 = d0 << 16;
	t0 *= x;
	t0 += d0 >> 8;
	d0 = data[1];
	t0 += d0 >> 20;
	t0 *= x;
	t0 >>= 18;
	d0 &= 0xfffff;
	t0 += d0;

	return t0;
}

int32_t cordic_atan2(int32_t y, int32_t x)
{
	int32_t z = 0;

	// abs(x) < abs(y) iff (x + y < 0) != (x - y < 0)
	auto abs_x_lt_abs_y = (x + y > 0) != (x - y > 0);

	if (abs_x_lt_abs_y) {
		std::tie(x, y) = std::make_pair(y, -x);
		z = 0x4000;
	}

	if (x < 0) {
		std::tie(x, y) = std::make_pair(-x, -y);
		z += 0x8000;
	}

	auto iter = [&](uint8_t hi, uint8_t lo, uint32_t i) {
		auto x0 = x;
		if (y < 0) {
			x = x - (y >> i);
			y = y + (x0 >> i);
			z = z - (hi << 8);
			z = z - lo;
		} else {
			x = x + (y >> i);
			y = y - (x0 >> i);
			z = z + (hi << 8);
			z = z + lo;
		}
	};

	iter(0x20, 0x00, 0);
	iter(0x12, 0xe4, 1);
	iter(0x09, 0xfb, 2);
	iter(0x05, 0x11, 3);
	iter(0x02, 0x8b, 4);
	iter(0x01, 0x46, 5);
	iter(0x00, 0xa3, 6);
	iter(0x00, 0x51, 7);
	iter(0x00, 0x29, 8);
	iter(0x00, 0x14, 9);

	z = (z < 0) ? (z + 0x10000) : z;

	return z;
}
