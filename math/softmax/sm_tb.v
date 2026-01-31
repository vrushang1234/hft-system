`timescale 1ns/1ps

module sm_tb;
    reg  signed [31:0] x [0:31];
    wire signed [31:0] y [0:31];

    sm_q32 dut (.x(x), .y(y));

    real q_scale = 536870912.0;
    integer i;

    initial begin
        $dumpfile("sm.vcd");
        $dumpvars(0, sm_tb);

        // Initialize 32 inputs with a mix of values (HIGH: i = 15 -> 1.5), (LOW: i = 0 -> 0.0)
        for (i = 0; i < 32; i = i + 1) begin
            x[i] = (i - 10) * 0.1 * q_scale; 
        end
        
        #100; 

        $display("Softmax 32-bit Q2.29 Results");
        for (i = 0; i < 32; i = i + 1) begin
            $display("Input[%0d]: %f  =>  Output[%0d]: %f", 
                      i, $signed(x[i])/q_scale, i, $signed(y[i])/q_scale);
        end

        $finish;
    end
endmodule