// tanh(x) using Q2.29 polynomial approximation
// 1 sign bit, 2 integer bits, 29 fractional bits

module tanh_q32 (
    input  signed [31:0] x,      // Q2.29
    output signed [31:0] y       // Q2.29
);
    // Constants scaled to Q2.29 (1.0 = 2^29)
    localparam signed [31:0] ONE_Q29     = 32'sd536870912; 
    localparam signed [31:0] NEG_ONE_Q29 = -32'sd536870912;
    localparam signed [31:0] INV3_Q29    = 32'sd178956970; // 1/3 in Q2.29
    localparam signed [31:0] C2_15_Q29   = 32'sd71582788;  // 2/15 in Q2.29

    // (Q2.29 * Q2.29 = Q5.58, shift back to Q2.29)
    wire signed [63:0] x2_full = $signed(x) * $signed(x);
    wire signed [31:0] x2      = x2_full >>> 29;

    // term1 = x^2 / 3
    wire signed [63:0] t1_full = $signed(x2) * $signed(INV3_Q29);
    wire signed [31:0] term1   = t1_full >>> 29;

    // x^4 = x^2 * x^2
    wire signed [63:0] x4_full = $signed(x2) * $signed(x2);
    wire signed [31:0] x4      = x4_full >>> 29;

    // term2 = 2*x^4 / 15
    wire signed [63:0] t2_full = $signed(x4) * $signed(C2_15_Q29);
    wire signed [31:0] term2   = t2_full >>> 29;

    // Polynomial p(x) = (1 - x^2/3 + 2x^4/15)
    wire signed [31:0] poly    = ONE_Q29 - term1 + term2;

    // y_raw = x * p(x)
    wire signed [63:0] y_full  = $signed(x) * $signed(poly);
    wire signed [31:0] y_poly  = y_full >>> 29;

    // Clamping for Softmax stability 
    // (1.2 in Q2.29 is 644,245,094) anyhting beyond --> forced to +/- 1.0
    assign y = (x > 32'sd644245094)  ? ONE_Q29 :
               (x < -32'sd644245094) ? NEG_ONE_Q29 :
               y_poly;
endmodule