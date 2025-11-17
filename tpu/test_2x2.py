# Generated with ChatGPT for ease of testing
import glob
import os
import subprocess
import sys

# -----------------------------
# Configuration
# -----------------------------

# Testbench top-level entity
TESTBENCH = "matrix2x2_tb"

# Generate a VCD file?
GENERATE_VCD = True

# -----------------------------
# Helper functions
# -----------------------------


def run(cmd):
    """Run a shell command, print it, and exit on error."""
    print("\n>>>", " ".join(cmd))
    result = subprocess.run(cmd)
    if result.returncode != 0:
        print("ERROR: Command failed:", " ".join(cmd))
        sys.exit(result.returncode)


def clean_ghdl_artifacts():
    """Remove GHDL build files and executables."""
    print("\n=== Cleaning old GHDL files ===")

    patterns = ["*.cf", "e~*", TESTBENCH, TESTBENCH + ".exe"]

    removed = False
    for p in patterns:
        for f in glob.glob(p):
            print("Removing:", f)
            os.remove(f)
            removed = True

    if not removed:
        print("No old files found.")


# -----------------------------
# Main Workflow
# -----------------------------

# Clean previous build
clean_ghdl_artifacts()

# Discover VHDL files
print("\n=== Discovering .vhd files ===")
vhd_files = sorted(glob.glob("*.vhd"))

if not vhd_files:
    print("No VHDL files found.")
    sys.exit(1)

for f in vhd_files:
    print("  ", f)

# Analyze VHDL files
print("\n=== Analyzing VHDL files ===")
for f in vhd_files:
    run(["ghdl", "-a", f])

# Elaborate
print("\n=== Elaborating testbench:", TESTBENCH, "===")
run(["ghdl", "-e", TESTBENCH])

# Run
print("\n=== Running simulation ===")
if GENERATE_VCD:
    run(["ghdl", "-r", TESTBENCH])
else:
    run(["ghdl", "-r", TESTBENCH])

print("\n=== Simulation complete ===")
