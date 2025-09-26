import gymnasium as gym
import numpy as np
from gymnasium import spaces


class HFTEnv(gym.Env):
    def __init__(self):
        super().__init__()
        self.action_space = spaces.Discrete(2)
        self.observation_space = spaces.Box(
            low=-10, high=10, shape=(1,), dtype=np.float32
        )

        self.state = np.zeros(1, dtype=np.float32)
        self.steps = 0
        self.max_steps = 100

    def reset(self, *, seed=None, options=None):
        super().reset(seed=seed)
        self.state[:] = 0.0
        self.steps = 0
        return self.state.copy(), {}

    def step(self, action):
        a = int(action)
        delta = 1.0 if a == 1 else -1.0
        self.state[0] += delta
        self.steps += 1

        reward = -abs(10.0 - float(self.state[0]))
        terminated = bool(self.state[0] >= 10.0)
        truncated = bool(self.steps >= self.max_steps)

        return self.state.copy(), float(reward), terminated, truncated, {}
