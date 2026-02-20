// 1/x Approximation for Softmax Sum
// Input: sum (Range 1.0 to 32.0) - requires wider input than Q2.29
// Output: 1/sum in Q2.29

module ra_q32 (
    input  [36:0] x,    
    output reg [31:0] y
);
    reg [31:0] lut [0:255];

    // Indexing based on the integer part of the sum (1.0 to 32.0)
    wire [7:0] idx = (x >= 37'h40000000) ? 8'd255 : x[28:21]; 

    initial begin
        $readmemh("recip_lut.mem", lut);
    end

    always @(*) y = lut[idx];
endmodule