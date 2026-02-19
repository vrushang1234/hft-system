import numpy as np
from stable_baselines3 import PPO
from environment import HFTEnv

env = HFTEnv()
model = PPO.load("ppo_hft") 

def to_hex8(val):
    val = val * 127.0  
    val = int(val)
    val = max(-128, min(127, val))
    return f"{val & 0xFF:02x}"

with open("test_cases.mem", "w") as f:
    
    reset_result = env.reset()
    obs = reset_result[0] if isinstance(reset_result, tuple) else reset_result
    
    for _ in range(100):
        action, _states = model.predict(obs, deterministic=True)

        f0 = to_hex8(obs[0])
        f1 = to_hex8(obs[1]) if len(obs) > 1 else "00"
        f2 = to_hex8(obs[2]) if len(obs) > 2 else "00"
        f3 = to_hex8(obs[3]) if len(obs) > 3 else "00"
        f4 = to_hex8(obs[4]) if len(obs) > 4 else "00"

        f.write(f"{f0}{f1}{f2}{f3}{f4}{int(action):02x}\n")

        step_result = env.step(action)
        
        if len(step_result) == 4:
            obs, reward, done, info = step_result
        else:
            obs, reward, done, truncated, info = step_result
            done = done or truncated

        if done:
            reset_result = env.reset()
            obs = reset_result[0] if isinstance(reset_result, tuple) else reset_result

print("Generated 100 stepped test cases in test_cases.mem")