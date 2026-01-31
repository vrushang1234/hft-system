// Softmax(x) = exp(x_i - max(x)) / sum(exp(x_j - max(x)))
// Format: Q2.29 (1 sign, 2 integer, 29 fractional bits)
// Scaling: 1.0 = 32'sd536870912

module sm_q32 (
    input  logic signed [31:0] x [32], 
    output logic signed [31:0] y [32]
);

    genvar i;

    // Binary Max Finder Tree: this finds the maximum value in the input vector to prevent exp() overflow.
    wire signed [31:0] m1 [16], m2 [8], m3 [4], m4 [2], maxv;
    
    generate
        for (i = 0; i < 16; i = i + 1) assign m1[i] = (x[2*i] > x[2*i+1]) ? x[2*i] : x[2*i+1];
        for (i = 0; i < 8;  i = i + 1) assign m2[i] = (m1[2*i] > m1[2*i+1]) ? m1[2*i] : m1[2*i+1];
        for (i = 0; i < 4;  i = i + 1) assign m3[i] = (m2[2*i] > m2[2*i+1]) ? m2[2*i] : m2[2*i+1];
        for (i = 0; i < 2;  i = i + 1) assign m4[i] = (m3[2*i] > m3[2*i+1]) ? m3[2*i] : m3[2*i+1];
    endgenerate
    assign maxv = (m4[0] > m4[1]) ? m4[0] : m4[1];

    // Exponential Units: this subtract maxv from each input (so all inputs are <= 0) and compute e^x.
    wire [31:0] e [32];
    generate
        for (i = 0; i < 32; i = i + 1) begin : exp_gen
            exp_q32 exp_inst (
                .x(x[i] - maxv), 
                .y(e[i])
            );
        end
    endgenerate

    // Binary Adder Tree: Summing 32 values of max 1.0 requires 37 bits to avoid overflow (max sum = 32.0).
    wire [36:0] s1 [16], s2 [8], s3 [4], s4 [2], sumv;
    generate
        for (i = 0; i < 16; i = i + 1) assign s1[i] = {5'b0, e[2*i]} + {5'b0, e[2*i+1]};
        for (i = 0; i < 8;  i = i + 1) assign s2[i] = s1[2*i] + s1[2*i+1];
        for (i = 0; i < 4;  i = i + 1) assign s3[i] = s2[2*i] + s2[2*i+1];
        for (i = 0; i < 2;  i = i + 1) assign s4[i] = s3[2*i] + s3[2*i+1];
    endgenerate
    assign sumv = s4[0] + s4[1];

    // Reciprocal Approximation: this computes 1 / sumv using the pre-calculated LUT.
    wire [31:0] inv_sum;
    ra_q32 recip_inst (
        .x(sumv), 
        .y(inv_sum)
    );

    // y_i = e_i * (1 / sum)
    generate
        for (i = 0; i < 32; i = i + 1) begin : mult_gen
            wire [63:0] prod = $unsigned(e[i]) * $unsigned(inv_sum);
            assign y[i] = prod[60:29]; // Shift right by 29 bits to return to Q2.29
        end
    endgenerate

endmodule