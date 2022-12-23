#include <stdarg.h>

#include <memory>

#include "nocash_printf.hpp"

static void nocash_puts(char const* str)
{
asm volatile(" \
	.global nocash_buffer \n\t\
	ldr r1, =nocash_buffer \n\t\
	mov r2, #0 \n\t\
.Lcopy_loop: \n\t\
	ldr r3, %[str] \n\t\
	ldrb r3, [r3, r2] \n\t\
	strb r3, [r1, r2] \n\t\
	cmp r3, #0 \n\t\
	beq .Lcopy_done \n\t\
	add r2, #1 \n\t\
	cmp r2, #80 \n\t\
	bne .Lcopy_loop \n\t\
.Lcopy_done: \n\t\
	mov r12, r12 \n\t\
	b .Lmsg_end \n\t\
	.hword 0x6464 \n\t\
	.hword 0x0 \n\t\
nocash_buffer: \n\t\
	.space 82 \n\t\
.Lmsg_end: \n\t"
	:
	: [str]"m" (str)
	: "r1", "r2", "r3", "cc");
}

void nocash_printf(char const* format, ...)
{
	char buffer[81];
	va_list args;
	va_start(args, format);
	vsnprintf(buffer, sizeof(buffer), format, args);

	nocash_puts(buffer);

	va_end(args);
}

void nocash_break(int condition)
{
	if (condition) {
asm volatile("mov r11, r11");
	}
}
