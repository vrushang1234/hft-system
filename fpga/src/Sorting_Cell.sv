import Constants::*;

module Sorting_Cell (
    input logic clk,
    input logic rst,
    input logic [1:0] instr,                    // 00:NOP    01:INSERT   10:REMOVE   11:INSREM
    input state_t instr_valid,                  // Goes high when a new instruction should be executed
    input logic [ADDR_WIDTH-1:0] addr,
    input logic [DATA_WIDTH-1:0] input_item,
    input logic [DATA_WIDTH-1:0] sram_dataout,
    
    input logic [DATA_WIDTH-1:0] left_item,
    input logic [DATA_WIDTH-1:0] right_item,
    
    output logic sram_we,
    output logic [ADDR_WIDTH-1:0] sram_addr,
    output logic [DATA_WIDTH-1:0] sram_datain,
    output logic [DATA_WIDTH-1:0] this_item
);

    logic sram_read_done_ff;
    FF_Load_Rst #(
        .DATA_WIDTH(1)
    ) sram_read_done_ff_inst (
        .clk(clk),
        .rst(rst),
        .d(instr_valid == VALID),
        .load(sram_read_done_ff || instr_valid),
        .q(sram_read_done_ff)
    );
  
    logic instr_ff_0;                         // Insert
    FF_Load_Rst #(
        .DATA_WIDTH(1)
    ) instr_ff_0_inst (
        .clk(clk),
        .rst(rst),
        .d(instr[0] && instr_valid),
        .load(sram_read_done_ff || instr_valid),
        .q(instr_ff_0)
    );
  
    logic instr_ff_1;                         // Remove
    FF_Load_Rst #(
        .DATA_WIDTH(1)
    ) instr_ff_1_inst (
        .clk(clk),
        .rst(rst),
        .d(instr[1] && instr_valid),
        .load(sram_read_done_ff || instr_valid),
        .q(instr_ff_1)
    );
  
    logic [ADDR_WIDTH-1:0] addr_ff;
    FF_Load #(
        .DATA_WIDTH(ADDR_WIDTH)
    ) addr_ff_inst (
        .clk(clk),
        .d(addr),
        .load(instr_valid == VALID),
        .q(addr_ff)
    );
  
    logic [DATA_WIDTH-1:0] input_item_ff;
    FF_Load #(
        .DATA_WIDTH(DATA_WIDTH)
    ) input_item_ff_inst (
        .clk(clk),
        .d(input_item),
        .load(instr_valid == VALID),
        .q(input_item_ff)
    );
  
    MUX_2_1 #(
        .DATA_WIDTH(ADDR_WIDTH)
    ) sram_addr_mux (
        .lo(addr),
        .hi(addr_ff),
        .s(sram_read_done_ff),
        .out(sram_addr)
    );
  
  
    always_comb begin 
        if (instr_ff_0 && instr_ff_1) begin                     // INSREM
            sram_datain = input_item_ff <= right_item ? input_item_ff : right_item;
        end
        else if (instr_ff_0) begin                              // INSERT
            if (input_item_ff <= sram_dataout) begin
                sram_datain = input_item_ff > left_item ? input_item_ff : left_item;
            end
        end 
        else if (instr_ff_1) begin                              // REMOVE
            sram_datain = right_item;
        end
        sram_we = instr_ff_0 || instr_ff_1 ? 1'b1 : 1'b0;
        this_item = sram_dataout;
    end

endmodule