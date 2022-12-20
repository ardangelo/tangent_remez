import math
import subprocess

# Approximate tan in range [0, pi/4) for binary angle measurements

coeff_fp = 18
divs = 32
width = int(0x2000 / divs)

def parse_fp(line):
	terms = line.split("x")
	af = float(terms[0].replace("(", "").replace("*", ""))
	bf = float(terms[1].replace(")*", ""))
	cf = float(terms[2])
	a = int(round(af * (1 << coeff_fp)))
	b = int(round(bf * (1 << coeff_fp)))
	c = int(round(cf * (1 << coeff_fp)))
	if any([x < 0 or x >= (1 << 32) for x in [a, b, c]]):
		raise Exception("Coefficient out of range " + str((a, b, c)))
	return (a, b, c)

def find_poly(func, lo, hi):
	proc = subprocess.Popen(
		["./lolremez/install/bin/lolremez", "--double", "-d", "2",
		"-r", f"{lo}:{hi}", func], stdout=subprocess.PIPE)
	result = None
	for line in proc.stdout:
		decoded = line.decode()
		if decoded.startswith("// p(x)="):
			func = parse_fp(decoded[8:])
			result = (func, decoded)
	return result


def to_float(x):
	return float(x) / 0x10000 * 2 * math.pi

# Generate polynomial coefficients along with a base value
# Constant coefficient will be added to base after shifting
coeffs = []
for i in range(divs):
	lo = i * width
	hi = (i + 1) * width
	base = math.tan(to_float(lo))
	expr = f"{1 << coeff_fp} * (tan((x + {lo}) / {0x10000} * 2 * pi) - {base})"
	(coeff, line) = find_poly(expr, 0, width)
	coeffs.append((coeff, int(base * (1 << coeff_fp))))

# Combine constant coefficient with post-shift base value
values = [(a, b, base + (c >> coeff_fp)) for ((a, b, c), base) in coeffs]

# Evaluate polynomial ((a * x) + b) * x at Q(2 * coeff_fp),
# Then shift and add constant c
def eval_poly(a, b, c, x):
	t1 = a
	t2 = (t1 * x) + b
	t3 = (t2 * x)
	t4 = (t3 >> coeff_fp) + c
	if any([t >= (1 << 32) for t in [t1, t2, t3, t4]]):
		raise Exception("overflow on " + str((a, b, c, x)))
	return int(t4)

# Determine maximum error and output found coefficients
max_err = (0, None)
for i in range(divs):
	(a, b, c) = values[i]
	for x in range(0,width):
		xr = to_float(i * width + x)
		actual = math.tan(xr)
		approx = float(eval_poly(a, b, c, x)) / (1 << coeff_fp)
		err = abs(actual - approx) * (1 << 16)
		if err > max_err[0]:
			max_err = (err, x)

if max_err[0] <= 1:
	print(f"tan_fp = {coeff_fp}")
	print(f"tan_divs = {divs}")
	print(f"tan_width = {width}")
	print(f"tan_values = {values}")
else:
	print(f"Maximum error {max_err[0]} at {hex(max_err[1])} exceeds 1")
