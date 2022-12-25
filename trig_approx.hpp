#pragma once

#include <cstdint>

extern "C" {
	int32_t _trig_approx(uint32_t x);
} // extern "C"

// Estimate tangent, 1/cosine of x in range (-pi/4, pi/4)
// x represented as binary angle measurement,
// (0xe000, 0xffff] U [0x0000, 0x2000)
// Return Q18 fixed point value
// Accurate within 2 bits at Q18
inline int32_t tan_approx(uint32_t x)
{
	auto sign = (x < 0x2000) ? 1 : -1;
	return sign * _trig_approx(x);
}

inline int32_t sec_approx(uint32_t x)
{
	return _trig_approx(x + 0x2000);
}
