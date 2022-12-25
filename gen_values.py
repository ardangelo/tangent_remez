import math
import subprocess

# Approximate tan and 1/cos in range [0, pi/4) for binary angle measurements

# Q18 result with 32 segments between [0, pi/4)
coeff_fp = 18
divs = 32
width = int(0x2000 / divs)

# Parse lolremez polynomial output line and return coefficients as Q18
def parse_fp(line):
	terms = line.split("x")
	af = float(terms[0].replace("(", "").replace("*", ""))
	bf = float(terms[1].replace(")*", ""))
	cf = float(terms[2])
	to_fp = lambda x: int(round(x * (1 << coeff_fp))) if x > 0 else 0
	a = to_fp(af)
	b = to_fp(bf)
	c = to_fp(cf)

	return (a, b, c)

# Use lolremez to find quadratic fitting function in range [lo, hi)
def find_poly(func, lo, hi):

	# Start lolremez
	proc = subprocess.Popen(
		["./lolremez/install/bin/lolremez", "--double", "-d", "2",
		"-r", f"{lo}:{hi}", func], stdout=subprocess.PIPE)

	# Find coefficients
	result = None
	for line in proc.stdout:
		decoded = line.decode()
		if decoded.startswith("// p(x)="):
			# Parse coefficients from polynomial line
			func = parse_fp(decoded[8:])
			result = (func, decoded)

	return result

# Convert BAM to radians
def to_float(x):
	return float(x) / 0x10000 * 2 * math.pi

# Generate polynomial coefficients along with a base value
# Constant coefficient will be added to base after bit shift right
# This allows for coefficients to all be in relatively similar range
# while considering fixed point shifting during calculation
# Coefficients will be packed into 8 bytes per poly
def find_values(base_func, expr_func):
	values = []
	for i in range(divs):

		# Angle range for this segment
		lo = i * width
		hi = (i + 1) * width

		base = base_func(lo)
		expr = expr_func(lo, base)

		# Run lolremez
		((a, b, c), line) = find_poly(expr, 0, width)

		# Combine constant coefficient with post-shift base value
		c = int(round(base * (1 << coeff_fp))) + (c >> coeff_fp)
		values.append((a, b, c))

	return values

tan_values = find_values(
	lambda lo:
		math.tan(to_float(lo)),
	lambda lo, base:
		f"{1 << coeff_fp} * (tan((x + {lo}) / {0x10000} * 2 * pi) - {base})")
sec_values = find_values(
	lambda lo:
		1.0 / math.cos(to_float(lo)),
	lambda lo, base:
		f"{1 << coeff_fp} * (1 / cos((x + {lo}) / {0x10000} * 2 * pi) - {base})")

# Evaluate polynomial ((a * x) + b) * x
# Then shift to adjust for FP multiplication and add constant c
def eval_poly(a, b, c, x):
	t1 = a
	t2 = (t1 * x) + b
	t3 = (t2 * x)
	t4 = (t3 >> coeff_fp) + c

	# Check for uint32 overflow on any intermediates
	if any([t >= (1 << 32) for t in [t1, t2, t3, t4]]):
		raise Exception("overflow on " + str((a, b, c, x)))

	return int(t4)

# Determine maximum error for range
def find_max_err(values, actual_func):
	max_err = (0, None)
	for i in range(divs):

		# Get values for range
		(a, b, c) = values[i]

		for x in range(0, width):

			# Convert BAM to radians
			xr = to_float(i * width + x)

			# Evaluate error
			actual = actual_func(xr) * (1 << coeff_fp)
			approx = float(eval_poly(a, b, c, x))
			err = abs(actual - approx)

			# Update max error
			if err > max_err[0]:
				max_err = (err, x)

	return max_err

tan_max_err = find_max_err(tan_values,
	lambda xr: math.tan(xr))
sec_max_err = find_max_err(sec_values,
	lambda xr: 1.0 / math.cos(xr))

print(f"fp = {coeff_fp}")
print(f"divs = {divs}")
print(f"width = {width}")

# If maximum error is acceptable, output generated values
if tan_max_err[0] <= 3:
	print(f"tan_values = {tan_values}")

else:
	print(f"Tangent maximum error {tan_max_err[0]} at {hex(tan_max_err[1])} exceeds 2 bits")

if sec_max_err[0] <= 3:
	print(f"sec_values = {sec_values}")

else:
	print(f"1/cosine error {sec_max_err[0]} at {hex(sec_max_err[1])} exceeds 2 bits")
