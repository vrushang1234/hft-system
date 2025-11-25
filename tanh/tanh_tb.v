`timescale 1ns/1ps


module tanh_tb;

    reg  signed [15:0] x;
    wire signed [15:0] y;

    tanh_q15 dut (.x(x), .y(y));

    integer i;

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tanh_tb);

        $display("%-12s %-12s %-12s %-12s",
         "x(Q15)", "float_x", "tanh(Q15)", "float_tanh");


        for (i = -32768; i <= 32767; i += 4096) begin
            x = i;
            #1;
            $display("%0d\t%0f\t%0d\t%0f",
                x,
                x / 32768.0,
                y,
                y / 32768.0
            );
        end

        $finish;
    end

endmodule
