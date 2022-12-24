#include "trig_approx.hpp"
#include "trig_array.gen.hpp"

static_assert(values::fp == 18);
static_assert(values::width == 0x100);

int32_t tan_approx(uint32_t x)
{
	auto sign = (x < 0x2000) ? 1 : -1;
	x = (x < 0x2000) ? x : (0x10000 - x);

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

	return sign * (int32_t)t0;
}

int32_t icos_approx(uint32_t x)
{
	x = (x < 0x2000) ? x : (0x10000 - x);
	x += 0x2000;

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
