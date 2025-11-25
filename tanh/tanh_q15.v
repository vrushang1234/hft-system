
// tanh(x) using Q15 polynomial approximation

// input: takes an input number (16 bit Q15)
// output: tanh(x) result (16 bit Q15)

module tanh_q15 (
    input  signed [15:0] x,
    output signed [15:0] y
);

    // Q15 × Q15 → Q30
    wire signed [31:0] x2 = x * x;

    // Convert x to Q30 for final multiply
    wire signed [31:0] x_q30 = x <<< 15;

    // Constants in Q30
    localparam signed [31:0] INV3_Q30        = 32'sd357913941; // 1/3 in Q30
    localparam signed [31:0] TWO_OVER_15_Q30 = 32'sd143165576; // 2/15 in Q30
    localparam signed [31:0] ONE_Q30         = 32'sd1073741824; // 1.0 in Q30

    // term1 = x^2 / 3 in Q30
    wire signed [63:0] mul_x2_inv3 = $signed(x2) * $signed(INV3_Q30); // Q30*Q30 -> Q60
    wire signed [31:0] term1_q30   = mul_x2_inv3 >>> 30;

    // x4 = x^4 in Q30
    wire signed [63:0] mul_x2_x2 = $signed(x2) * $signed(x2); // Q30*Q30 -> Q60
    wire signed [31:0] x4_q30     = mul_x2_x2 >>> 30;

    // term2 = 2*x^4/15 in Q30
    wire signed [63:0] mul_x4_c = $signed(x4_q30) * $signed(TWO_OVER_15_Q30); // Q30*Q30 -> Q60
    wire signed [31:0] term2_q30 = mul_x4_c >>> 30;

    // Polynomial: p(x) = 1 - x^2/3 + 2*x^4/15
    wire signed [31:0] p_q30 = $signed(ONE_Q30) - $signed(term1_q30) + $signed(term2_q30);

    // Final multiply: y = x * p(x)
    wire signed [63:0] mul_xp = $signed(x_q30) * $signed(p_q30); // Q30*Q30 -> Q60
    wire signed [31:0] y_q30 = mul_xp >>> 30;

    // Back to Q15 for rounding
    wire signed [15:0] out = y_q30[30:15];

    // Saturation clamp [-1, 1] for Q15 range
    assign y =
        (out == -16'sh8000) ? 16'sh7FFF : out;

endmodule
