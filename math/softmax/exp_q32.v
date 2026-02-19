// exp(x) for Q2.29 (32-bit)
// Input: x <= 0, Range [-4.0, 0.0]
// Output: y in range (0, 1.0]

module exp_q32 (x, y);
    input  [31:0] x;
    output [31:0] y;

    // 256-entry LUT for the range [-4.0, 0.0]
    reg [31:0] lut [0:255];
    
    // Shift -4.0 to 0.0. Range becomes [0.0, 4.0]
    wire [31:0] x_offset = x + 32'h80000000;
    
    // Check Bit 31: If Bit 31 is 1, it means we hit 4.0 (or overflowed slightly), --> clamp to index 255 (max value). Else, we take bits [30:23].
    wire [7:0] idx = (x_offset[31]) ? 8'd255 : x_offset[30:23];

    initial begin
        $readmemh("exp_lut.mem", lut);
    end

    assign y = lut[idx];
endmodule