`timescale 1ns/1ps

module tanh_tb;
    reg  signed [31:0] x;
    wire signed [31:0] y;

    tanh_q32 dut (.x(x), .y(y));

    real q_scale = 536870912.0; // 2^29
    integer i;

    initial begin
        $dumpfile("tanh.vcd");
        $dumpvars(0, tanh_tb);

        $display("%-12s %-12s %-12s %-12s", "x(Hex)", "float_x", "y(Hex)", "float_tanh");

        // Test from -2.0 to 2.0 in steps of 0.25
        // 0.25 in Q2.29 is 0.25 * 2^29 = 134217728
        for (i = -1073741824; i <= 1073741824; i += 134217728) begin
            x = i;
            #1;
            $display("%h\t%0f\t%h\t%0f", x, x / q_scale, y, y / q_scale);
        end
        $finish;
    end
endmodule