import math
# to_q29_hex.py
# Used to create exp_lut.mem for exp_q32.v and ra_lut.mem for ra_q32.v

# Converts a float to a 32-bit Q2.29 hex string.
def to_q29_hex(val):
    scale = 2**29
    scaled_val = int(round(val * scale))
    return f"{scaled_val & 0xFFFFFFFF:08x}"


# Generates Exponential LUT (exp_lut.mem) -- Range: -4.0 to 0.0 (256 entries)
with open("math/softmax/exp_lut.mem", "w") as f:
    for i in range(256):
        x = -4.0 + (i * 4.0 / 255.0)
        y = math.exp(x)
        f.write(to_q29_hex(y) + "\n")

# Generates Reciprocal LUT (ra_lut.mem) -- Range: 1.0 to 32.0 (256 entries)
with open("math/softmax/ra_lut.mem", "w") as f:
    for i in range(256):
        x = 1.0 + (i * 31.0 / 255.0)
        y = 1.0 / x
        f.write(to_q29_hex(y) + "\n")

print("Generated exp_lut.mem and ra_lut.mem successfully.")