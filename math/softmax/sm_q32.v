// Softmax(x) = exp(x_i - max(x)) / sum(exp(x_j - max(x)))
// Format: Q2.29 (1 sign, 2 integer, 29 fractional bits)
// Scaling: 1.0 = 32'sd536870912

module sm_q32 (
    input  logic clk,
    input  logic rst,
    input  logic signed [63:0] d_in,     // Two 32-bit values packed together
    output logic signed [63:0] prob_out  // Two 32-bit probabilities packed together
);

    // Unpack the input vector into two 32-bit signals
    wire signed [31:0] x0 = d_in[63:32];
    wire signed [31:0] x1 = d_in[31:0];

    // Find Max (to prevent overflow)
    wire signed [31:0] maxv = (x0 > x1) ? x0 : x1;

    // Compute Exponentials: e^(x - max)
    wire [31:0] e0, e1;
    
    exp_q32 exp0 (.x(x0 - maxv), .y(e0));
    exp_q32 exp1 (.x(x1 - maxv), .y(e1));

    // Sum the Exponentials
    // We add bits to prevent overflow during summation
    wire [32:0] sumv = {1'b0, e0} + {1'b0, e1};

    // Reciprocal: 1 / sumv
    wire [31:0] inv_sum;
    ra_q32 recip_inst (
        .x({4'b0, sumv}), // Adjusting bit-width for your Reciprocal unit
        .y(inv_sum)
    );

    // Final Normalization: y = e * (1/sum)
    wire [63:0] prod0 = $unsigned(e0) * $unsigned(inv_sum);
    wire [63:0] prod1 = $unsigned(e1) * $unsigned(inv_sum);

    // Pack the results back into a single output vector
    // Shifting by 29 to handle Q2.29 fixed point math
    assign prob_out[63:32] = prod0[60:29]; 
    assign prob_out[31:0]  = prod1[60:29];

endmodule