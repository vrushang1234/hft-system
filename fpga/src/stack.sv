`timescale 1ns / 1ps

import Constants::*;

//////////////////////////////////////////////////////////////////////////////////
// A standard FILO stack using BRAM
// See: https://www.chipverify.com/verilog/verilog-stack-lifo
//////////////////////////////////////////////////////////////////////////////////

module stack #(
    // Constant to RAMB18E1
    parameter WIDTH = 16,
    parameter DEPTH = 1024
)(
    input wire              clk,
    input wire              rst,
    input wire              push,
    input wire              pop,
    input wire [WIDTH-1:0]  data_in,
    output reg [WIDTH-1:0]  data_out,
    output reg              empty,
    output reg              full
);

    reg [WIDTH-1:0]        stack [0:DEPTH-1];
    reg [$clog2(DEPTH):0]  stack_ptr;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            stack_ptr <= 0;
            empty <= 1;
            full <= 0;

        end else begin
            if (push && !full) begin
                stack[stack_ptr] <= data_in;
                stack_ptr        <= stack_ptr + 1;
                empty            <= 0;

                if (stack_ptr == DEPTH - 1) begin
                    full <= 1;
                end

            end else if (pop && !empty) begin
                stack_ptr <= stack_ptr - 1;
                full      <= 0;

                if (stack_ptr == 1) begin
                    empty <= 1;
                end
            end
        end
    end

    always @(*) begin
      if (!empty & pop)
            data_out = stack[stack_ptr - 1];
        else
            data_out = {WIDTH{1'b0}};
    end

endmodule