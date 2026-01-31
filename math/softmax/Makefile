SRC = sm_q32.v exp_q32.v ra_q32.v
TB  = sm_tb.v
OUT = sm_sim.vvp
VCD = sm.vcd

FLAGS = -g2012

run: compile simulate

compile:
	@echo Compiling Verilog sources ==
	iverilog $(FLAGS) -o $(OUT) $(SRC) $(TB)

simulate:
	@echo Running simulation ==
	vvp $(OUT)

view: $(VCD)
	@echo Running GTKWave ==
	gtkwave $(VCD)

clean:
	-del /Q $(OUT) $(VCD) 2>nul