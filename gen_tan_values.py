import math
import subprocess

# Approximate tan in range [0, pi/4) for binary angle measurements

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
	a = int(round(af * (1 << coeff_fp)))
	b = int(round(bf * (1 << coeff_fp)))
	c = int(round(cf * (1 << coeff_fp)))

	# Check for uint32 overflow
	if any([x < 0 or x >= (1 << 32) for x in [a, b, c]]):
		raise Exception("Coefficient out of range " + str((a, b, c)))

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
coeffs = []
for i in range(divs):

	# Angle range for this segment
	lo = i * width
	hi = (i + 1) * width

	# All values relative to output for beginning of range
	base = math.tan(to_float(lo))
	# Incorporate base adjustment and BAM conversion into lolremez expression
	expr = f"{1 << coeff_fp} * (tan((x + {lo}) / {0x10000} * 2 * pi) - {base})"
	# Run lolremez
	(coeff, line) = find_poly(expr, 0, width)
	# Save coefficients and base value
	coeffs.append((coeff, int(base * (1 << coeff_fp))))

# Combine constant coefficient with post-shift base value
values = [(a, b, base + (c >> coeff_fp)) for ((a, b, c), base) in coeffs]

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
max_err = (0, None)
for i in range(divs):

	# Get values for range
	(a, b, c) = values[i]

	for x in range(0,width):

		# Convert BAM to radians
		xr = to_float(i * width + x)

		# Evaluate error
		actual = math.tan(xr)
		approx = float(eval_poly(a, b, c, x)) / (1 << coeff_fp)
		err = abs(actual - approx) * (1 << 16)

		# Update max error
		if err > max_err[0]:
			max_err = (err, x)

# If maximum error is acceptable, output generated values
if max_err[0] <= 1:
	print(f"tan_fp = {coeff_fp}")
	print(f"tan_divs = {divs}")
	print(f"tan_width = {width}")
	print(f"tan_values = {values}")

else:
	print(f"Maximum error {max_err[0]} at {hex(max_err[1])} exceeds 1")
