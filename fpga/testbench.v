`timescale 100ps / 1ps



module testbench();
    reg clk;
    reg push;
    reg pop;
    reg peek;
    reg [31:0] wr_val;
    wire [31:0] rd_val;
    wire empty;
    wire full;


    queue q(
    .clk(clk),
    .push(push),
    .pop(pop),
    .peek(peek),
    .wr_val(wr_val),
    .rd_val(rd_val),
    .empty(empty),
    .full(full)
    );

    always begin
        #5;
        clk = ~clk;
    end


    initial begin
        clk = 0;
        push = 1'b1;
        #1;
        wr_val = 'h1A2B;
        #1;
        push = 1'b0;
        #4;
        peek = 1'b1;
        #5;
        peek = 1'b0;
        push = 1'b1;
        wr_val = 'h3C4D;
        #2;
        pop = 1'b1;
    end

endmodule