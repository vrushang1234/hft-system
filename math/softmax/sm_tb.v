`timescale 1ns/1ps

module sm_tb;
    reg clk;
    reg rst;
    reg  signed [63:0] d_in;       // 2x 32-bit packed inputs
    wire signed [63:0] prob_out;   // 2x 32-bit packed outputs

    sm_q32 dut (
        .clk(clk),
        .rst(rst),
        .d_in(d_in),
        .prob_out(prob_out)
    );

    real q_scale = 536870912.0; // 1.0 in Q2.29
    integer i;

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("sm.vcd");
        $dumpvars(0, sm_tb);

        // Reset
        rst = 1;
        d_in = 64'd0;
        #20 rst = 0;
        #10;

        $display("--- Softmax 2-Way Q2.29 Results ---");
        
        // keep x1 at 0.0, and sweep x0 from -1.0 to +1.0
        for (i = 0; i <= 10; i = i + 1) begin
            
            d_in[63:32] = (i - 5) * 0.2 * q_scale; // x0
            d_in[31:0]  = 0 * q_scale;             // x1
            
            #10;
            
            $display("Input  [x0: %f, x1: %f]  =>  Output [p0: %f, p1: %f]", 
                      $signed(d_in[63:32]) / q_scale, 
                      $signed(d_in[31:0])  / q_scale,
                      $signed(prob_out[63:32]) / q_scale, 
                      $signed(prob_out[31:0])  / q_scale);
        end

        $finish;
    end
endmodule