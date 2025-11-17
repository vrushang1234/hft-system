# Generated with ChatGPT for ease of testing
import glob
import os
import subprocess
import sys

TESTBENCH = "matmul_l1_tb"
GENERATE_VCD = True


def run(cmd):
    print("\n>>>", " ".join(cmd))
    result = subprocess.run(cmd)
    if result.returncode != 0:
        print("ERROR:", " ".join(cmd))
        sys.exit(result.returncode)


def clean_ghdl_artifacts():
    print("\n=== Cleaning old GHDL files ===")
    patterns = ["*.cf", "e~*", TESTBENCH, TESTBENCH + ".exe"]
    for p in patterns:
        for f in glob.glob(p):
            print("Removing:", f)
            os.remove(f)


print("\n=== Cleaning GHDL files ===")
clean_ghdl_artifacts()

print("\n=== Discovering .vhd files ===")
all_vhd = sorted(glob.glob("*.vhd"))

for f in all_vhd:
    print("  ", f)

# ---------------------------
# FORCED COMPILATION ORDER
# ---------------------------
ordered_files = []

# 1) matmul_types.vhd MUST BE FIRST
if "matmul_types.vhd" in all_vhd:
    ordered_files.append("matmul_types.vhd")

# 2) Then everything else EXCEPT testbench
for f in all_vhd:
    if f not in ordered_files and f != TESTBENCH + ".vhd":
        ordered_files.append(f)

# 3) Testbench LAST
if TESTBENCH + ".vhd" in all_vhd:
    ordered_files.append(TESTBENCH + ".vhd")

print("\n=== Compilation order ===")
for f in ordered_files:
    print("  ", f)

print("\n=== Analyzing files ===")
for f in ordered_files:
    run(["ghdl", "-a", "--std=08", f])

print("\n=== Elaborating testbench ===")
run(["ghdl", "-e", "--std=08", TESTBENCH])

print("\n=== Running simulation ===")
cmd = ["ghdl", "-r", "--std=08", TESTBENCH]
if GENERATE_VCD:
    cmd.append("--vcd=wave.vcd")

run(cmd)

print("\n=== Simulation complete ===")
