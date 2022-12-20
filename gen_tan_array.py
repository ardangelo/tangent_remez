from tan_values_gen import tan_fp, tan_divs, tan_values, tan_width

print("#pragma once")
print("#include <cstdint>")

print("namespace tan_values {")
print(f"static constexpr uint32_t fp = {tan_fp};")
print(f"static constexpr uint32_t divs = {tan_divs};")
print(f"static constexpr uint32_t width = {tan_width};")

print("// uint32_t data[] = {0xaabbbbbc, 0xccccdddd};")
print(f"uint32_t data[{2 * tan_divs}] =")

first = True
for (a, b, c) in tan_values:
	if a > 0xfff:
		raise Exception(f"Overflow on a = {hex(a)}")
	if b > 0xffffff:
		raise Exception(f"Overflow on b = {hex(b)}")
	if c > 0xfffff:
		raise Exception(f"Overflow on c = {hex(c)}")

	d0 = (a << 20) | (b >> 4)
	d1 = ((b & 0xf) << 20) | c

	print(f"// a = {hex(a)}, b = {hex(b)}, c = {hex(c)}")
	delim = "{" if first else ","
	print(f"{delim} {hex(d0)}, {hex(d1)}")
	first = False

print("};")
print("}")
