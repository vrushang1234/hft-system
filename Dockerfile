FROM python:3.12-slim-bookworm

RUN apt-get update && apt-get install -y iverilog ghdl make bash build-essential gtkwave nodejs npm && rm -rf /var/lib/apt/lists/*

RUN npm install -g prettier@3.7.4 && pip install black==25.12.0 isort==7.0.0

WORKDIR /repo
ENTRYPOINT ["/bin/bash"]
