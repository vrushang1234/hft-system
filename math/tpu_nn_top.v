`timescale 1ns / 1ps

module tpu_nn_top (
    input  wire        clk,
    input  wire        rst,
    input  wire [39:0] order_features, // 5 features * 8-bits = 40 bits
    output wire        action_rank     // 1-bit rank (0 or 1)
);

    // Internal Signals 
    wire [2047:0] l1_activated_flat; // 64 neurons * 32-bits from Layer 1
    wire [2047:0] l2_activated_flat; // 64 neurons * 32-bits from Layer 2
    wire [63:0]   l3_out_flat;       // 2 neurons * 32-bits from Layer 2
    wire [63:0]   softmax_out_flat;  // 2 probabilities * 32-bits
    
    // 1. Layer 1 (Input 5 -> 64 + Tanh)
    tpu_layer1_complete u_layer1 (
        .clk(clk),
        .rst(rst),
        .features(order_features), 
        .layer_out_flat(l1_activated_flat) 
    );
    
    // 2. Layer 2 (Hidden 64 -> 64 + Tanh)
    tpu_layer2_complete u_layer2 (
        .clk(clk),
        .rst(rst),
        .activated_in(l1_activated_flat),  // 64 inputs from L1
        .layer_out_flat(l2_activated_flat) // 64 outputs from L2 Tanh
    );

    // 3. Layer 3 / Output Layer (Hidden 64 -> 2)
    matmul_l3 u_layer3 (
        .clk(clk),
        .activated_in(l2_activated_flat),  // 64 inputs 
        .l3_out(l3_out_flat)               // 2 outputs (64 bits)
    );

    // 4. Softmax
    sm_q32 u_softmax (
        .clk(clk),
        .rst(rst),
        .d_in(l3_out_flat),           // 2x 32-bit Q2.29 inputs
        .prob_out(softmax_out_flat)   // 2x 32-bit Q2.29 outputs
    );

    // 5. ArgMax
    argmax_2way u_ranker (
        .prob_0(l3_out_flat[31:0]),  // Action 0 (Sell) directly from Layer 3
        .prob_1(l3_out_flat[63:32]), // Action 1 (Buy) directly from Layer 3
        .rank(action_rank)               
    );

endmodule