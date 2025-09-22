from stable_baselines3 import PPO
from environment import HFTEnv 

env = HFTEnv()
model = PPO("MlpPolicy", env, verbose=1)
model.learn(total_timesteps=10_000)
