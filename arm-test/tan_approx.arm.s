.section .iwram, "ax", %progbits
.align 2
.arm
.global tan_approx
tan_approx:
	@ if (x < 0x2000) {
	cmp     r0, #8192
	@	x = 0x10000 - x
	rsbcs   r0, r0, #65536
	@	Store sign bit in top bit of stack pointer
	@	Stack pointer is word-aligned, so at least lower bit is unset
	@	sp = (1 << 31) | (sp >> 1);
	rrx     sp, sp
	@ }

	@ Save a load by adding array offset to program counter
	@ ldr     r3, =tan_lut
	add     r3, pc, #64

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
	@ three cycle stall from mla (covers ldr)

	@ r2 = (0x0aaa * x) + 0x00bbbb00 + 0x0bb
	@    = (0x0aaa * x) + 0x00bbbbbb
	add     r2, r2, r1, asr #20
	@ r0 = ((0x0aaa * x) + 0x00bbbbbb) * x
	mul     r0, r2, r0
	@ r0 = 0xcccc'c000
	lsl     r1, r1, #12
	@ one cycle stall from mul (covers lsl)

	@ r2 = (((0x0aaa * x) + 0x00bbbbbb) * x) >> 18
	lsr     r2, r0, #18
	@ r0 = ((((0x0aaa * x) + 0x00b'bbbbb) * x) >> 18) + 0x000c'cccc
	add     r0, r2, r1, lsr #12

	@ Get sign bit back out of stack pointer
	@ if (sp & (1 << 31); sp <<= 1) {
	lsls    sp, sp, #1
	@	r0 = -r0
	rsbcs   r0, r0, #0
	@ }

	bx      lr

.global tan_lut
tan_lut:
	.word 0x86485, 0x500000
	.word 0x176494, 0x8401923
	.word 0x2764c3, 0x170324e
	.word 0x376510, 0xf904b88
	.word 0x47657e, 0x89064da
	.word 0x57660c, 0x5007e4c
	.word 0x6866bb, 0x1097e5
	.word 0x7a678b, 0x790b1ae
	.word 0x8c687e, 0xc30cbaf
	.word 0x9e6996, 0x1c0e5f2
	.word 0xb26ad2, 0xf41007f
	.word 0xc76c36, 0xf211b61
	.word 0xdc6dc3, 0xfc136a0
	.word 0xf36f7c, 0x3a15248
	.word 0x10b7162, 0x1c16e64
	.word 0x1257378, 0x6718b00
	.word 0x14175c2, 0x351a827
	.word 0x15e7843, 0x71c5e8
	.word 0x17e7afe, 0xcf1e450
	.word 0x1a07df9, 0xfc20370
	.word 0x1c58139, 0x8e22356
	.word 0x1ed84c3, 0x2524416
	.word 0x219889d, 0x1c265c3
	.word 0x2498cce, 0xa128870
	.word 0x27d915f, 0xd32ac37
	.word 0x2b79659, 0xec2d12e
	.word 0x2f79bc7, 0x672f773
	.word 0x33ea1b4, 0x3931f23
	.word 0x38ca82e, 0xd34860
	.word 0x3e4af44, 0x933734e
	.word 0x445b709, 0xd73a019
	.word 0x4b4bf92, 0xb53ceed
