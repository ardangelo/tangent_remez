#include "tan_approx.hpp"
#include "tan_array.gen.hpp"

// Run tangent approximation for x in [0, pi/4)
uint32_t tan_approx_(uint32_t const* data, uint32_t x)
{
	// uint32_t data[] = {0xaaabbbbb, 0x00bccccc};
	// ((((a * x) + b) * x) >> tan_fp) + c
	auto d0 = data[0];
	auto t0 = d0 >> 20;
	t0 *= x;
	t0 += (d0 & 0xfffff) << 4;
	auto d1 = data[1];
	t0 += d1 >> 20;
	t0 *= x;
	t0 >>= tan_values::fp;
	t0 += d1 & 0xfffff;

	return t0;
}

// Tangent approximation for x in (-pi/4,pi/4) with result in Q18
int32_t tan_approx(uint32_t x)
{
	auto sign = (x < 0x2000) ? 1 : -1;
	x = (x < 0x2000) ? x : (0x10000 - x);
	auto data = tan_values::data + 2 * (x / tan_values::width);
	return sign * tan_approx_(data, x % tan_values::width);
}
