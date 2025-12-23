import Constants::*;

//////////////////////////////////////////////////////////////////////////////////
// A standard D FlipFlop with load, d will update to q when load is high
//////////////////////////////////////////////////////////////////////////////////

module FF_Load #(
    parameter DATA_WIDTH = Constants::DATA_WIDTH
)(
    input  logic                  clk,
    input  logic                  load,
    input  logic [DATA_WIDTH-1:0] d,
    output logic [DATA_WIDTH-1:0] q = 0
);

    always_ff @(posedge clk) begin
        if (load) 
            q <= d;
    end

endmodule

//////////////////////////////////////////////////////////////////////////////////
// A FlipFlop with load and reset
//////////////////////////////////////////////////////////////////////////////////

module FF_Load_Rst #(
    parameter DATA_WIDTH = Constants::DATA_WIDTH
)(
    input  logic                  clk,
    input  logic                  load,
    input  logic                  rst,
    input  logic [DATA_WIDTH-1:0] d,
    output logic [DATA_WIDTH-1:0] q = 0
);

    always_ff @(posedge clk) begin
        if (rst) 
            q <= {DATA_WIDTH{1'b0}};
        else if (load) 
            q <= d;
    end

endmodule

//////////////////////////////////////////////////////////////////////////////////
// 2-1 Multiplexer
//////////////////////////////////////////////////////////////////////////////////

module MUX_2_1 #(
    parameter DATA_WIDTH = 1
)(
    input  logic [DATA_WIDTH-1:0] lo,
    input  logic [DATA_WIDTH-1:0] hi,
    input  logic                  s,
    output logic [DATA_WIDTH-1:0] out
);

    assign out = s ? hi : lo;

endmodule