import os
import math
import subprocess
import re

# Directories and Config
TANH_DIR = "tanh"
SM_DIR   = "softmax"
Q_SCALE  = 2**29 

def to_q29_hex(val):
    limit = 2**31 - 1
    scaled = int(round(val * Q_SCALE))
    clamped = int(max(-limit - 1, min(limit, scaled)))
    return f"{clamped & 0xFFFFFFFF:08x}"

def python_softmax(inputs):
    exps = [math.exp(x) for x in inputs]
    sum_exps = sum(exps)
    return [e / sum_exps for e in exps]

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
            if i == 255:
                x = 0.0 
            else:
                x = -4.0 + ((i + 0.5) * 0.015625)
            f.write(to_q29_hex(math.exp(x)) + "\n")

    # Reciprocal LUT
    with open(os.path.join(SM_DIR, "recip_lut.mem"), "w") as f:
        for i in range(256):
            if i == 255:
                val_x = 2.0
            else:
                val_x = 1.0 + ((i + 0.5) * 0.00390625)
            f.write(to_q29_hex(1.0 / val_x) + "\n")

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
        print("\n[*] Verifying Tanh Accuracy...")
        print(f"{'Input':>10} | {'Verilog':>12} | {'Python':>12} | {'Error':>12}")
        print("-" * 55)
        
        matches = re.findall(r"^\s*([-.\d]+)\s+\|\s+([-.\d]+)", out_t, re.MULTILINE)
        max_error = 0
        for val_in, val_out in matches:
            actual = float(val_out)
            expected = math.tanh(float(val_in))
            error = abs(actual - expected)
            if error > max_error: max_error = error
            print(f"{val_in:>10} | {actual:12.6f} | {expected:12.6f} | {error:12.6f}")
        print(f"Max Tanh Error: {max_error:.6f}")

    print("\n--- Testing Softmax ---")
    out_s = run_sim("s_sim", ["sm_tb.v", "sm_q32.v", "exp_q32.v", "ra_q32.v"], SM_DIR)
    if out_s:
        print("\n[*] Verifying Softmax Accuracy...")
    
        regex_pattern = r"Input\s*\[x0:\s*([-.\d]+),\s*x1:\s*([-.\d]+)\]\s*=>\s*Output\s*\[p0:\s*([-.\d]+),\s*p1:\s*([-.\d]+)\]"
        s_matches = re.findall(regex_pattern, out_s)
        
        if s_matches:
            print(f"{'Input (x0, x1)':>15} | {'Verilog (p0, p1)':>20} | {'Python (p0, p1)':>20} | {'Max Error':>12}")
            print("-" * 75)
            
            global_max_err = 0
            for m in s_matches:
                x0, x1, p0, p1 = map(float, m)
            
                py_p0, py_p1 = python_softmax([x0, x1])
                
                err0 = abs(p0 - py_p0)
                err1 = abs(p1 - py_p1)
                row_max_err = max(err0, err1)
                
                if row_max_err > global_max_err:
                    global_max_err = row_max_err
                
                print(f"{x0:6.2f}, {x1:6.2f} | {p0:9.6f}, {p1:9.6f} | {py_p0:9.6f}, {py_p1:9.6f} | {row_max_err:12.6f}")
                
            print("-" * 75)
            print(f"Max Softmax Error: {global_max_err:.6f}")
        else:
            print("[!] Could not parse Softmax output. Check Verilog $display formatting.")

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