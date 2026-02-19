`timescale 1ns / 1ps

// TODO:
// - Test INSREM
// - Implement small clusters with shared flip flops for sorting cells
// - Find a better way to check and handle #TCQ = 100ps read delay

import Constants::*;

module tb_MultiQueue();

    logic                  clk;
    logic                  rst;
    logic                  op_en;
    logic [1:0]            instr;
    logic [DATA_WIDTH-1:0] input_item;

    logic                  busy;
    logic [DATA_WIDTH-1:0] output_item;

    MultiQueue MultiQueue_inst (
        .clk        (clk),
        .rst        (rst),
        .op_en      (op_en),
        .instr      (instr),
        .input_item (input_item),
        .busy       (busy),
        .output_item(output_item)
    );

    always begin
        #1;
        clk = ~clk;
    end

    // Verification Task
    task verify_output(input logic [DATA_WIDTH-1:0] expected_val);
        assert (output_item === expected_val) 
            $display("[PASS] Time %0t: Output matched expected value %h", $time, output_item);
        else 
            $error("[FAIL] Time %0t: Expected %h, but got %h", $time, expected_val, output_item);
    endtask

    initial begin
        clk = 0;
        rst = 1;

        #102.4;
        rst = 0;

        #4;

        // --- Insert ---
        input_item = 72'hAAAAAAAAAAAAAAAAAA;
        instr      = 2'b01;
        op_en      = 1;

        #2 op_en = 0;

        #2 input_item = 72'hBBBBBBBBBBBBBBBBBB;
        op_en         = 1;

        #2 op_en = 0;

        #2 input_item = 72'h00000000000000BBBB;
        op_en         = 1;

        #2 op_en = 0;

        // --- Remove ---
        #2 instr   = 2'b10;
        input_item = 72'hXXXXXXXXXXXXXXAAAA;
        op_en      = 1;

        #2 op_en = 0;

        #2 op_en = 1; 
        
        verify_output(72'hAAAAAAAAAAAAAAAAAA); 

        #2 op_en = 0;
        
        #10
        
        // --- InsRem ---
        #2 instr   = 2'b11;
        input_item = 72'hCCCCCCCCCCCCCCCCCC;
        op_en      = 1;

        #2 op_en = 0;

        #2 op_en = 1;
        
        verify_output(72'hBBBBBBBBBBBBBBBBBB);

        #2 op_en = 0;
        
        #10 $finish;
    end

endmodule