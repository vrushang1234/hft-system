// exp(x) for Q2.29 (32-bit)
// Input: x <= 0, Range [-4.0, 0.0]
// Output: y in range (0, 1.0]

module exp_q32 (
    input  signed [31:0] x,
    output reg    [31:0] y
);
    // 256-entry LUT for the range [-4.0, 0.0]
    reg [31:0] lut [0:255];
    
    // Using a 10-bit fraction for the index to keep it smooth
    // Range -4.0 (32'h80000000) to 0.0 in Q2.29:
    
    wire [7:0] idx = (x <= -32'sd2147483648) ? 8'd0 : // Clamp to -4.0
                     (x >= 0)                ? 8'd255 :
                     (x[30:23] + 8'd128);             // Map range to 0-255

    initial begin
        $readmemh("exp_lut.mem", lut);
    end

    always @(*) y = lut[idx];
endmodule