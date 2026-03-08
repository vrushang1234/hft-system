module hardware_test_wrapper (
    input wire clk // Physical Pin W5
);

    wire [39:0] vio_features;
    wire        vio_rst;
    wire        vio_rank;

    // TPU
    tpu_nn_top u_tpu (
        .clk(clk),
        .rst(vio_rst),
        .order_features(vio_features), 
        .action_rank(vio_rank)
    );

    // VIO Core
    // Output Probe 0: 40 bits (for order_features)
    // Output Probe 1: 1 bit  (for rst)
    // Input Probe 0:  1 bit  (for action_rank)
    vio_0 vio_inst (
        .clk(clk),
        .probe_in0(vio_rank),      
        .probe_out0(vio_features), 
        .probe_out1(vio_rst)
    );

endmodule