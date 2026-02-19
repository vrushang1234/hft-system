`timescale 1ns / 1ps

import Constants::*;

//////////////////////////////////////////////////////////////////////////////////
// Controller interface for a group/cluster of sorting cells
//////////////////////////////////////////////////////////////////////////////////

module Sorting_Cell_Cluster #(
    parameter bit INIT_VAL = 1'b0
)(
    input  logic                  clk,
    input  logic                  rst,
    input  logic [1:0]            instr,
    input  state_t                instr_valid,
    input  logic [DATA_WIDTH-1:0] input_item,
    input  logic [ADDR_WIDTH-1:0] addr,
    input  logic [DATA_WIDTH-1:0] sram_dataout [BLOCKS-1:0],

    output logic                  sram_we      [BLOCKS-1:0],
    output logic [ADDR_WIDTH-1:0] sram_addr,                    // Common address for 1 cluster
    output logic [DATA_WIDTH-1:0] sram_datain  [BLOCKS-1:0],

    output logic [DATA_WIDTH-1:0] output_item
);

    logic [DATA_WIDTH-1:0] links     [BLOCKS+1:0];
    logic [DATA_WIDTH-1:0] this_item [BLOCKS-1:0];

    genvar i;
    generate
        for (i = 0; i < BLOCKS; i = i + 1) begin
            Sorting_Cell Sorting_Cell_inst (
                .clk          (clk),
                .rst          (rst),
                .instr        (instr),                      // 00:NOP    01:INSERT   10:REMOVE   11:INSREM
                .instr_valid  (instr_valid == VALID),       // Goes high when a new instruction should be executed
                .addr         (addr),
                .input_item   (input_item),
                .sram_dataout (sram_dataout[i]),

                .sram_we      (sram_we[i]),
                .sram_addr    (sram_addr),
                .sram_datain  (sram_datain[i]),

                .left_item    (links[i]),
                .right_item   (links[i+2]),
                .this_item    (links[i+1])
            );
        end
    endgenerate

    logic sram_read_done_ff;
    FF_Load_Rst #(
        .DATA_WIDTH(1)
    ) sram_read_done_ff_inst (
        .clk  (clk),
        .rst  (rst),
        .d    (instr_valid == VALID),
        .load (sram_read_done_ff || instr_valid),
        .q    (sram_read_done_ff)
    );

    logic instr_ff_1;                          // Remove
    FF_Load_Rst #(
        .DATA_WIDTH(1)
    ) instr_ff_1_inst (
        .clk  (clk),
        .rst  (rst),
        .d    (instr[1] && instr_valid),
        .load (sram_read_done_ff || instr_valid),
        .q    (instr_ff_1)
    );

    initial begin
        for (int k = 1; k < BLOCKS+1; k = k + 1) begin
            links[k] = {DATA_WIDTH{INIT_VAL}};
        end
        links[0] = {DATA_WIDTH{INIT_VAL}};
        links[BLOCKS+1] = {DATA_WIDTH{INIT_VAL}};
    end

    always_comb begin
        output_item = instr_ff_1 ? links[1] : {DATA_WIDTH{INIT_VAL}};
    end

endmodule