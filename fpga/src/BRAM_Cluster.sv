import Constants::*;

//////////////////////////////////////////////////////////////////////////////////
// Controller interface for a group/cluster of 72 bit BRAM wrapper modules
//////////////////////////////////////////////////////////////////////////////////

module BRAM_Cluster #(
    parameter INIT_VAL = 0
)(
    input  logic                  clk,
    input  logic                  rst,
    input  logic                  en,
    input  logic                  wr_en   [BLOCKS-1:0],
    input  logic [ADDR_WIDTH-1:0] addr,
    input  logic [DATA_WIDTH-1:0] wr_data [BLOCKS-1:0],
    output logic [DATA_WIDTH-1:0] rd_data [BLOCKS-1:0]
);

    genvar i;
    generate
        for (i = 0; i < BLOCKS; i = i + 1) begin
            RAMB72_Wrapper #(
                .INIT_VAL(INIT_VAL)
            ) RAMB72_Wrapper_inst (
                .clk     (clk),
                .rst     (rst),
                .en      (en),
                .wr_en   (wr_en[i]),
                .addr    (addr),
                .wr_data (wr_data[i]),
                
                .rd_data (rd_data[i])
            );
        end
    endgenerate

endmodule