`timescale 1ns / 1ps

import Constants::*;

//////////////////////////////////////////////////////////////////////////////////
// A controller that handles write on miss for CAM
//////////////////////////////////////////////////////////////////////////////////

module CAM_Controller(
    input  logic                  clk,
    input  logic                  rst,
    input  state_t                instr_valid,
    input  logic [DATA_WIDTH-1:0] input_item,

    output logic                  hit,
    output logic [ADDR_WIDTH-1:0] out_addr
);

    logic [ADDR_WIDTH-1:0] write_ptr;
    wire  [ADDR_WIDTH-1:0] cam_out_addr;

    wire  [15:0]           stock_id    = input_item[15:0];
    wire  [15:0]           stock_id_ff;

    wire                   rd_en       = (instr_valid == VALID);
    logic                  wr_en       = 0;

    wire  [15:0]           cam_tagin   = (instr_valid == VALID) ? stock_id : stock_id_ff;

    FF_Load #(
        .DATA_WIDTH(16)
    ) addr_ff_inst (
        .clk  (clk),
        .d    (stock_id),
        .load (rd_en),
        .q    (stock_id_ff)
    );

    CAM #(
        .WIDTH      (16),               // temporary: replace with actual stock id length
        .DEPTH      (ADDR_DEPTH),
        .ADDR_WIDTH (ADDR_WIDTH)
    ) CAM_inst (
        .clk      (clk),
        .rst      (rst),
        .rd_en    (rd_en),
        .wr_en    (wr_en),
        .wr_addr  (write_ptr),
        .tagin    (cam_tagin),
        
        .hit      (hit),
        .out_addr (cam_out_addr)
    );

    always_ff @(posedge clk) begin
        if (rst) begin
            write_ptr <= '0;
            wr_en     <= '0;
        end else begin
            wr_en <= (!hit) && (instr_valid == VALID);
            if (wr_en) begin
                if (write_ptr == BLOCKS - 1)
                    write_ptr <= 0;
                else
                    write_ptr <= write_ptr + 1;
            end
        end
    end

    assign out_addr = hit ? cam_out_addr : write_ptr;

endmodule