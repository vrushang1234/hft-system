`timescale 1ns / 1ps

import Constants::*;

//////////////////////////////////////////////////////////////////////////////////
// A modified implementation of a MultiQueue, as described here: https://www.mdpi.com/2079-9268/12/3/39
// Instead of priority queues, min-queues are used to store items in exact order
// Content Addressable Memory is used to select the target queue address based on an ID from the input
//////////////////////////////////////////////////////////////////////////////////

module MultiQueue (
    input  logic                  clk,
    input  logic                  rst,
    input  logic                  op_en,       // Whether or not to execute the instruction
    input  logic [1:0]            instr,
    input  logic [DATA_WIDTH-1:0] input_item,

    output logic                  busy,
    output logic [DATA_WIDTH-1:0] output_item

    // output logic [1:0] err_code 
);

    state_t               instr_state;
    wire                  addr_valid;
    wire [ADDR_WIDTH-1:0] item_addr;

    wire [ADDR_WIDTH-1:0] cam_out_addr;
    wire [ADDR_WIDTH-1:0] sram_addr;

    wire [DATA_WIDTH-1:0] bram_rd_data [BLOCKS-1:0];
    wire                  bram_wr_en   [BLOCKS-1:0];
    wire [DATA_WIDTH-1:0] bram_wr_data [BLOCKS-1:0];

    CAM_Controller CAM_Controller_inst (
        .clk        (clk),
        .rst        (rst),
        .instr_valid(instr_state),
        .input_item (input_item),
        
        .hit        (addr_valid),
        .out_addr   (cam_out_addr)
    );

    Sorting_Cell_Cluster #(
        .INIT_VAL(1)
    ) Sorting_Cell_Cluster_inst (
        .clk          (clk),
        .rst          (rst),
        .instr        (instr),
        .instr_valid  (instr_state),
        .input_item   (input_item),
        .addr         (cam_out_addr),
        .sram_dataout (bram_rd_data),
        
        .sram_we      (bram_wr_en),
        .sram_addr    (sram_addr),       // Common address for 1 cluster
        .sram_datain  (bram_wr_data),
        .output_item  (output_item)
    );

    BRAM_Cluster #(
        .INIT_VAL(1'b1)
    ) BRAM_Cluster_inst (
        .clk     (clk),
        .rst     (rst),
        .en      (1'b1),                 // always enabled for now
        .wr_en   (bram_wr_en),
        .addr    (sram_addr),
        .wr_data (bram_wr_data),
        
        .rd_data (bram_rd_data)
    );

    always_ff @(posedge clk) begin
        if (rst || instr_state == VALID)
            instr_state <= INVALID;
        else if (op_en)
            instr_state <= VALID;
    end

endmodule