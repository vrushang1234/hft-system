SRC = tanh_q15.v
TB  = tanh_tb.v
OUT = tanh_sim.vvp
VCD = dump.vcd

# // iverilog -o tanh_sim tanh_q15.v tanh_tb.v
# vvp tanh_sim

run: compile simulate

compile:
	@echo Compiling Verilog sources...
	iverilog -o $(OUT) $(SRC) $(TB)

simulate:
	@echo Running simulation...
	vvp $(OUT)

view: $(VCD)
	@echo Running GTKWave...
	gtkwave $(VCD)

clean:
	-del /Q $(OUT) $(VCD) 2>nul