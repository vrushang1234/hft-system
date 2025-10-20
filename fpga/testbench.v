`timescale 1ns / 1ps



module testbench();
    reg clk;
    wire write;
    wire pop;
    wire peek;
    wire [15:0] write_value;
    wire [15:0] read_value;


    queue q(
    .clk(clk),
    .write(write),
    .pop(pop),
    .peek(peek),
    .write_value(write_value),
    .read_value(read_value)
    );

    always begin
        #10;
        clk = ~clk;
    end

    initial 
        clk = 0;

endmodule