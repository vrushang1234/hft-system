import numpy as np
import torch
from stable_baselines3 import PPO


def export_weights_to_vhdl(model):
    l1_weights = model.policy.mlp_extractor.policy_net[0].weight.detach().cpu().numpy()
    l2_weights = model.policy.mlp_extractor.policy_net[2].weight.detach().cpu().numpy()
    l3_weights = model.policy.action_net.weight.detach().cpu().numpy()

    print(f"Model L1 Shape: {l1_weights.shape} (Expected 64x5)")
    print(f"Model L2 Shape: {l2_weights.shape} (Expected 64x64)")
    print(f"Model L3 Shape: {l3_weights.shape} (Expected 2x64)")

    with open("tpu_weights_pkg.vhd", "w") as f:
        f.write(
            "library ieee;\nuse ieee.std_logic_1164.all;\nuse ieee.numeric_std.all;\nuse work.matmul_types.all;\n\n"
        )
        f.write("package tpu_weights_pkg is\n\n")

        # --- LAYER 1: 64 neurons, 5 inputs ---
        f.write("    constant WEIGHTS_L1 : matrix64x5 := (\n")
        for r in range(64):
            f.write("        (")
            for c in range(5):
                if c < l1_weights.shape[1]:
                    val = int(l1_weights[r][c] * 127.0)
                else:
                    val = 0  # Fill missing features with 0

                val = max(-128, min(127, val))
                f.write(f"to_signed({val}, 8)")
                if c < 4:
                    f.write(", ")
            f.write(")")
            if r < 63:
                f.write(",\n")
        f.write("\n    );\n\n")

        # --- LAYER 2: 64 neurons, 64 inputs ---
        f.write("    constant L2_WEIGHTS : weight_matrix_64x64 := (\n")
        for r in range(64):
            f.write("        (")
            for c in range(64):
                if c < l2_weights.shape[1]:
                    val = int(l2_weights[r][c] * 127.0)
                else:
                    val = 0

                val = max(-128, min(127, val))
                f.write(f"to_signed({val}, 8)")
                if c < 63:
                    f.write(", ")
            f.write(")")
            if r < 63:
                f.write(",\n")
        f.write("\n    );\n\n")

        # --- LAYER 3: 2 outputs, 64 inputs ---
        f.write("    constant L3_WEIGHTS : weight_matrix_2x64 := (\n")
        for r in range(2):
            f.write("        (")
            for c in range(64):
                if c < l3_weights.shape[1]:
                    val = int(l3_weights[r][c] * 127.0)
                else:
                    val = 0

                val = max(-128, min(127, val))
                f.write(f"to_signed({val}, 8)")
                if c < 63:
                    f.write(", ")
            f.write(")")
            if r < 1:
                f.write(",\n")
        f.write("\n    );\n\n")

        f.write("end package tpu_weights_pkg;\n")

    print("SUCCESS: 'tpu_weights_pkg.vhd' created with all 3 layers.")


if __name__ == "__main__":
    try:
        model = PPO.load("ppo_hft")
        export_weights_to_vhdl(model)
    except Exception as e:
        print(f"Error: {e}")
