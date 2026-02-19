// tanh(x) using Q2.29 polynomial approximation
// 1 sign bit, 2 integer bits, 29 fractional bits

module tanh_q32 (x, y);
    input  [31:0] x;
    output [31:0] y;

    reg [31:0] lut [0:1023];
    
    // x_offset shifts -4.0 (0x80000000) to 0.0
    // and 0.0 to 4.0 (0x80000000)
    wire [31:0] x_offset = x + 32'h80000000;
    
    // For a 1024 entry table over range 8.0:
    // Bit 31 represents 4.0. (31 down to 22) for 10 bits.
    wire [9:0] idx = x_offset[31:22];

    initial begin
        $readmemh("tanh_lut.mem", lut);
    end

    assign y = lut[idx];
endmodule