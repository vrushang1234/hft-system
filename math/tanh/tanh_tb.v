`timescale 1ns/1ps

module tanh_tb;
    reg  signed [31:0] x;
    wire signed [31:0] y;
    reg clk;

    // Instantiate DUT
    tanh_q32 dut (.x(x), .y(y));

    real q_scale = 536870912.0; // 2^29
    integer k; // Loop counter
    real float_x, float_y;

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("tanh.vcd");
        $dumpvars(0, tanh_tb);

        $display("\n--- Tanh Q2.29 Check ---");
        $display("%-10s | %-10s | %-10s | %-10s", "Input(F)", "Output(F)", "Input(H)", "Output(H)");
        $display("------------------------------------------------------------");

        x = 32'h80000000; 

        // Run 64 steps across the full range
        for (k = 0; k < 64; k = k + 1) begin
            
            @(posedge clk); 
            #1; // Allow signal to settle

            float_x = x / q_scale;
            float_y = $signed(y) / q_scale;

            $display("%10.4f | %10.4f | %h | %h", float_x, float_y, x, y);

            // Increment x by a large chunk (approx 0.125 in float)
            x = x + 32'd67108864;
        end

        $display("------------------------------------------------------------");
        $finish;
    end
endmodule