.section .iwram, "ax", %progbits
.align 2
.arm
.global tan_approx
tan_approx:
	cmp     r0, #8192
	orrcs   lr, lr, #268435456
	rsbcs   r0, r0, #65536
	@ldr     r3, =tan_lut
	add     r3, pc, #72
	lsr     r2, r0, #8
	add     r1, r3, r2, lsl #3
	ldr     r3, [r3, r2, lsl #3]
	lsl     r2, r3, #16
	and     r0, r0, #255
	lsr     r3, r3, #16
	lsr     r2, r2, #8
	mla     r2, r3, r0, r2
	ldr     r1, [r1, #4]
	add     r2, r2, r1, asr #20
	mul     r0, r2, r0
	lsr     r2, r0, #18
	bic     r0, r1, #-16777216
	bic     r0, r0, #15728640
	add     r0, r0, r2
	lsrs    r3, lr, #28
	rsbne   r0, r0, #0
	bic     lr, lr, #-268435456
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
