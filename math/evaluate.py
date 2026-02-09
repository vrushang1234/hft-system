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
        print(out_t)
    else:
        print("[FAIL] No Tanh output received.")

    print("\n--- Testing Softmax ---")
    out_s = run_sim("s_sim", ["sm_tb.v", "sm_q32.v", "exp_q32.v", "ra_q32.v"], SM_DIR)
    if out_s:
        print(out_s)
    else:
        print("[FAIL] No Softmax output received.")

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