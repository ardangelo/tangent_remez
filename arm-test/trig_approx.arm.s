.section .iwram, "ax", %progbits
.align 2
.arm
.global sec_approx
sec_approx:
	@ Symmetric
	cmp     r0, #32768
	rsbcs   r0, r0, #65536
	@ secant values 0x2000 after tangent values
	add     r0, r0, #8192
	@ Fall through to tan_approx

.section .iwram, "ax", %progbits
.align 2
.arm
.global tan_approx
tan_approx:
	@ if (x < 0x8000) {
	cmp     r0, #32768
	@	x = 0x10000 - x
	rsbcs   r0, r0, #65536
	@	Sign bit is conserved as carry bit
	@ }

	@ Get coefficient array address
	adr     r3, trig_lut

	@ data = &tan_lut[x / 0x100]
	@ coefficients in form {0x0aaa'bbbb, 0x0bbc'cccc}
	lsr     r2, r0, #8
	add     r1, r3, r2, lsl #3
	@ r3 = 0x0aaa'bbbb
	ldr     r3, [r3, r2, lsl #3]

	@ x %= 0x100
	@ Calculate ((((a * x) + b) * x) >> 18) + c
	and     r0, r0, #255

	@ r2 = 0xbbbb'0000
	lsl     r2, r3, #16

	@ r3 = 0x0aaa
	lsr     r3, r3, #16
	@ r2 = 0x00bbbb00
	lsr     r2, r2, #8
	@ r2 = (0x0aaa * x) + 0x00bbbb00
	mla     r2, r3, r0, r2
	@ r1 = 0x0bbc'cccc
	ldr     r1, [r1, #4]

	@ r2 = (0x0aaa * x) + 0x00bbbb00 + 0x0bb
	@    = (0x0aaa * x) + 0x00bbbbbb
	add     r2, r2, r1, asr #20
	@ r0 = ((0x0aaa * x) + 0x00bbbbbb) * x
	mul     r0, r2, r0
	@ r1 = 0xcccc'c000
	lsl     r1, r1, #12

	@ r2 = (((0x0aaa * x) + 0x00bbbbbb) * x) >> 18
	lsr     r2, r0, #18
	@ r0 = ((((0x0aaa * x) + 0x00b'bbbbb) * x) >> 18) + 0x000c'cccc
	add     r0, r2, r1, lsr #12

	@ Adjust sign for result
	rsbcs   r0, r0, #0

	bx      lr

.global trig_lut
trig_lut:

	@ tangent lut
	.word 0x86485, 0x500000
	.word 0x176494, 0x8401923
	.word 0x2764c3, 0x170324e
	.word 0x376510, 0xf904b89
	.word 0x47657e, 0x89064db
	.word 0x57660c, 0x5007e4c
	.word 0x6866bb, 0x1097e5
	.word 0x7a678b, 0x790b1ae
	.word 0x8c687e, 0xc30cbb0
	.word 0x9e6996, 0x1c0e5f2
	.word 0xb26ad2, 0xf410080
	.word 0xc76c36, 0xf211b61
	.word 0xdc6dc3, 0xfc136a1
	.word 0xf36f7c, 0x3a15249
	.word 0x10b7162, 0x1c16e65
	.word 0x1257378, 0x6718b00
	.word 0x14175c2, 0x351a828
	.word 0x15e7843, 0x71c5e8
	.word 0x17e7afe, 0xcf1e451
	.word 0x1a07df9, 0xfc20370
	.word 0x1c58139, 0x8e22357
	.word 0x1ed84c3, 0x2524417
	.word 0x219889d, 0x1c265c3
	.word 0x2498cce, 0xa128871
	.word 0x27d915f, 0xd32ac37
	.word 0x2b79659, 0xec2d12f
	.word 0x2f79bc7, 0x672f773
	.word 0x33ea1b4, 0x3931f23
	.word 0x38ca82e, 0xd34860
	.word 0x3e4af44, 0x933734f
	.word 0x445b709, 0xd73a019
	.word 0x4b4bf92, 0xb53ceee

	@ secant lut
	.word 0x13c0000, 0x40000
	.word 0x13d0277, 0xb84004f
	.word 0x13f04f1, 0x6a4013c
	.word 0x142076e, 0xef402c8
	.word 0x14609f2, 0x3a404f4
	.word 0x14b0c7d, 0x46407c2
	.word 0x1500f12, 0x2240b34
	.word 0x15811b2, 0xeb40f4d
	.word 0x1601461, 0xd941410
	.word 0x1691721, 0x3e41980
	.word 0x17419f3, 0x8d41fa3
	.word 0x1801cdb, 0x624267d
	.word 0x18e1fdb, 0x8442e14
	.word 0x19d22f6, 0xee4366e
	.word 0x1ae2630, 0xd743f93
	.word 0x1c1298c, 0xbb4498b
	.word 0x1d62d0e, 0x624545f
	.word 0x1ed30b9, 0xf046018
	.word 0x2073493, 0xef46cc2
	.word 0x22338a1, 0x5d47a69
	.word 0x2433ce7, 0xc04891a
	.word 0x266416d, 0x35498e5
	.word 0x28d4638, 0x8f4a9da
	.word 0x2b84b51, 0x6a4bc0b
	.word 0x2e850c0, 0x4f4cf8e
	.word 0x31d568e, 0xda4e478
	.word 0x3585cc7, 0xe24fae3
	.word 0x39b6377, 0xb5512ec
	.word 0x3e56aac, 0x5052cb1
	.word 0x4397275, 0xaf54856
	.word 0x4977ae6, 0x2956602
	.word 0x5028412, 0xdd585e2

.section .iwram, "ax", %progbits
.align 2
.arm
.global _cordic_atan2
_cordic_atan2:

@ Adjust angle to range (-pi/4, pi/4)
@ Input: r0 x, r1 y
@ Output: r0 angle, r1 y, r3 x

	@ abs(x) < abs(y) iff (x + y < 0) != (x - y < 0)
	@ r2 = (x + y > 0) ^ (x - y > 0)
	add r2, r0, r1
	sub r3, r0, r1
	eors r2, r2, r3

	@ if (abs(x) < abs(y)) {
	@	(x, y) = (y, -x)
	movmi r3, r1
	rsbmi r1, r0, #0
	@	angle = pi/2
	movmi r0, #0x4000
	@ } else {
	@	(x, y) = (x, y)
	movpl r3, r0
	@	angle = 0 }
	movpl r0, #0

	@ if (x < 0) {
	cmp r3, #0
	@	(x, y) = (-x, -y)
	rsblt r3, r3, #0
	rsblt r1, r1, #0
	@	angle += pi }
	addlt r0, #0x8000

_cordic_atan2_core:
	cmp     r1, #0
	sublt   r0, r0, #0x2000
	addgt   r0, r0, #0x2000
	sublt   r2, r3, r1
	addge   r2, r1, r3
	addlt   r3, r1, r3
	subge   r3, r1, r3

	cmp     r3, #0
	sublt   r0, r0, #4800
	addge   r0, r0, #4800
	sublt   r1, r2, r3, asr #1
	addge   r1, r2, r3, asr #1
	addlt   r3, r3, r2, asr #1
	subge   r3, r3, r2, asr #1
	sublt   r0, r0, #36
	addge   r0, r0, #36

	cmp     r3, #0
	sublt   r0, r0, #2544
	addge   r0, r0, #2544
	sublt   r2, r1, r3, asr #2
	addge   r2, r1, r3, asr #2
	addlt   r3, r3, r1, asr #2
	subge   r3, r3, r1, asr #2
	sublt   r0, r0, #11
	addge   r0, r0, #11

	cmp     r3, #0
	sublt   r0, r0, #1296
	addge   r0, r0, #1296
	sublt   r1, r2, r3, asr #3
	addge   r1, r2, r3, asr #3
	addlt   r3, r3, r2, asr #3
	subge   r3, r3, r2, asr #3
	sublt   r0, r0, #1
	addge   r0, r0, #1

	cmp     r3, #0
	sublt   r0, r0, #648
	addge   r0, r0, #648
	sublt   r2, r1, r3, asr #4
	addge   r2, r1, r3, asr #4
	addlt   r3, r3, r1, asr #4
	subge   r3, r3, r1, asr #4
	sublt   r0, r0, #3
	addge   r0, r0, #3

	cmp     r3, #0
	sublt   r0, r0, #324
	addge   r0, r0, #324
	sublt   r1, r2, r3, asr #5
	addge   r1, r2, r3, asr #5
	addlt   r3, r3, r2, asr #5
	subge   r3, r3, r2, asr #5
	sublt   r0, r0, #2
	addge   r0, r0, #2

	cmp     r3, #0
	addlt   r3, r3, r1, asr #6
	subge   r3, r3, r1, asr #6
	sublt   r0, r0, #163
	addge   r0, r0, #163

	cmp     r3, #0
	sublt   r2, r1, r3, asr #7
	addge   r2, r1, r3, asr #7
	addlt   r3, r3, r1, asr #7
	subge   r3, r3, r1, asr #7
	sublt   r0, r0, #81
	addge   r0, r0, #81

	cmp     r3, #0
	addlt   r3, r3, r2, asr #8
	subge   r3, r3, r2, asr #8
	sublt   r0, r0, #41
	addge   r0, r0, #41

	cmp     r3, #0
	sublt   r0, r0, #20
	addge   r0, r0, #20

	cmp     r0, #0
	addlt   r0, #0x10000

	bx      lr
