#pragma once

#include <cstdint>

extern "C" {

// Estimate tangent of x in range (-pi/4, pi/4)
// x represented as binary angle measurement,
// (0xe000, 0xffff] U [0x0000, 0x2000)
// Return Q18 fixed point value
// Accurate within 2 bits at Q18
int32_t tan_approx(uint32_t x);

int32_t icos_approx(uint32_t x);

} // extern "C"
