SRC = tanh_q32.v
TB  = tanh_tb.v
OUT = tanh_sim.vvp
VCD = tanh.vcd

run: compile simulate

compile:
	@echo Compiling Verilog sources ==
	iverilog -o $(OUT) $(SRC) $(TB)

simulate:
	@echo Running simulation == 
	vvp $(OUT)

view: $(VCD)
	@echo Running GTKWave ==
	gtkwave $(VCD)

clean:
	-del /Q $(OUT) $(VCD) 2>nul
