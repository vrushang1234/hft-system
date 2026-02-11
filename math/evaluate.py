import os
import math
import subprocess

# Directories and Config
TANH_DIR = "tanh"
SM_DIR   = "softmax"
Q_SCALE  = 2**29 

def to_q29_hex(val):
    limit = 2**31 - 1
    scaled = int(round(val * Q_SCALE))
    clamped = int(max(-limit - 1, min(limit, scaled)))
    return f"{clamped & 0xFFFFFFFF:08x}"

def generate_luts():
    print("[*] Generating LUTs...")
    
    # Tanh LUT
    os.makedirs(TANH_DIR, exist_ok=True)
    with open(os.path.join(TANH_DIR, "tanh_lut.mem"), "w") as f:
        for i in range(1024):
            x = -4.0 + (i * 8.0 / 1024.0)
            f.write(to_q29_hex(math.tanh(x)) + "\n")

    # Exp LUT
    os.makedirs(SM_DIR, exist_ok=True)
    with open(os.path.join(SM_DIR, "exp_lut.mem"), "w") as f:
        for i in range(256):
            x = -4.0 + (i * 4.0 / 256.0)
            f.write(to_q29_hex(math.exp(x)) + "\n")

    # Reciprocal LUT
    with open(os.path.join(SM_DIR, "recip_lut.mem"), "w") as f:
        for i in range(256):
            val_x = i * 0.125 
            val_y = 1.0 / val_x if val_x > 0.06 else 16.0
            f.write(to_q29_hex(val_y) + "\n")

def run_sim(name, files, folder):
    out_bin = os.path.join(folder, name)
    paths = [os.path.join(folder, f) for f in files]
    
    print(f"[*] Compiling {name} in {folder}...")
    compile_proc = subprocess.run(["iverilog", "-g2012", "-o", out_bin] + paths, 
                                  capture_output=True, text=True)
    
    if compile_proc.returncode != 0:
        print(f"[!] Compilation Error:\n{compile_proc.stderr}")
        return None
        
    print(f"[*] Running {name} simulation...")
    # cwd=folder ensures it finds .mem files
    res = subprocess.run(["vvp", name], cwd=folder, capture_output=True, text=True)
    
    if not res.stdout.strip():
        print(f"[!] Simulation produced no output. Stderr: {res.stderr}")
        return None
        
    return res.stdout

if __name__ == "__main__":
    generate_luts()
    
    print("\n--- Testing Tanh ---")
    out_t = run_sim("t_sim", ["tanh_tb.v", "tanh_q32.v"], TANH_DIR)
    if out_t:
        print("[*] Verifying Tanh Accuracy...")
        import re
        matches = re.findall(r"^\s*([-.\d]+)\s+\|\s+([-.\d]+)", out_t, re.MULTILINE)
        
        if not matches:
            print("    [!] Warning: Could not parse Tanh output table.")
        else:
            max_error = 0
            for val_in, val_out in matches:
                actual = float(val_out)
                expected = math.tanh(float(val_in))
                error = abs(actual - expected)
                if error > max_error: max_error = error
                
            print(f"    Max Error Found: {max_error:.6f}")
            if max_error < 0.005: 
                print("    [RESULT] Tanh Verification: PASS")
            else:
                print("    [RESULT] Tanh Verification: FAIL (Error too high)")


    print("\n--- Testing Softmax ---")
    out_s = run_sim("s_sim", ["sm_tb.v", "sm_q32.v", "exp_q32.v", "ra_q32.v"], SM_DIR)
    if out_s:
        print("\n[*] Verifying Softmax Accuracy...")
        s_matches = re.findall(r"Input\[\d+\]:\s+([-.\d]+)\s+=>\s+Output\[\d+\]:\s+([-.\d]+)", out_s)
        
        if s_matches:
            # Probability Check (outputs sum to ~1.0)
            total_prob = sum(float(m[1]) for m in s_matches)
            print(f"    Total Probability Sum: {total_prob:.6f}")
            if 0.99 <= total_prob <= 1.01:
                print("    [RESULT] Softmax Verification: PASS")
            else:
                print("    [RESULT] Softmax Verification: FAIL (Does not sum to 1.0)")

    # Cleanup
    print("\n[*] Cleaning up artifacts...")
    artifacts = [
        os.path.join(TANH_DIR, "t_sim"),
        os.path.join(TANH_DIR, "tanh.vcd"),
        os.path.join(SM_DIR, "s_sim"),
        os.path.join(SM_DIR, "sm.vcd")
    ]
    for f in artifacts:
        if os.path.exists(f):
            try:
                os.remove(f)
                print(f"    Deleted: {f}")
            except OSError:
                pass