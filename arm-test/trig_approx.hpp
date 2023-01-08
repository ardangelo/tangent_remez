#pragma once

#include <cstdint>
#include <tuple>

// Implementations in trig_approx.arm.s
extern "C" {

	// Input r0 angle
	// Output r0 Q18 tan(angle)
	int32_t tan_approx(uint32_t angle);

	// Input r0 angle
	// Output r0 Q18 tan(angle)
	int32_t sec_approx(uint32_t angle);

	// Input r0 x, r1 y
	// Output r0 angle
	uint32_t _cordic_atan2(int32_t x, int32_t y);
} // extern "C"

static inline uint32_t cordic_atan2(int32_t x, int32_t y)
{
	return _cordic_atan2(x, y);
}

static inline int32_t adj_cordic_hyp(int32_t x)
{
	constexpr auto gain = (int32_t)round(float(1 << 8) / 1.64676);
	return (x * gain) >> 8;
}

static inline auto cordic_atan2_hyp(int32_t x, int32_t y)
{
	// Constrain x to r0, y to r1
	register int32_t r0 __asm__ ("r0") = x;
	register int32_t r1 __asm__ ("r1") = y;

	// Call assembly _cordic_atan2
	// Input r0 x, r1 y
	// Output r0 angle, r1 gained hypotenuse
	asm volatile("bl _cordic_atan2"
		: "+r" (r0), "+r" (r1)
		: "r" (r0), "r" (r1)
		: "r2", "r3", "lr");

	// Return values
	auto angle = int32_t{r0};
	auto hyp = int32_t{r1};

	return std::make_pair(angle, hyp);
}
