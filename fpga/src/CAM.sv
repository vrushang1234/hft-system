import Constants::*;

//////////////////////////////////////////////////////////////////////////////////
// Content addressable memory block
//////////////////////////////////////////////////////////////////////////////////

module CAM #(
    parameter WIDTH,
    parameter DEPTH,
    parameter ADDR_WIDTH
)(
    input  logic                  clk,
    input  logic                  rst,
    input  logic                  rd_en,
    input  logic                  wr_en,
    input  logic [ADDR_WIDTH-1:0] wr_addr,
    input  logic [WIDTH-1:0]      tagin,

    output logic                  hit,
    output logic [ADDR_WIDTH-1:0] out_addr
);

    logic [WIDTH-1:0] data  [DEPTH-1:0];
    logic             valid [DEPTH-1:0];

    always_comb begin
        hit      = 1'b0;
        out_addr = '0;

        if (rd_en) begin
            for (int i = 0; i < DEPTH; i++) begin
                if (valid[i] && (data[i] == tagin)) begin
                    hit      = 1'b1;
                    out_addr = i[ADDR_WIDTH-1:0];
                    break;
                end
            end
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            valid <= '{default:0};
        end 
        else if (wr_en) begin
            data[wr_addr]  <= tagin;
            valid[wr_addr] <= 1'b1;
        end
    end

endmodule