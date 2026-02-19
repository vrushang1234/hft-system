`timescale 1ns / 1ps

module argmax_2way (
    input  wire signed [31:0] prob_0, // Action 0 (Sell / -1.0)
    input  wire signed [31:0] prob_1, // Action 1 (Buy / +1.0)
    output reg                rank    // 0 or 1
);

    always @(*) begin
        // Force signed two's complement comparison
        if ($signed(prob_1) > $signed(prob_0)) begin
            rank = 1'b1; 
        end 
        // Otherwise, output 0
        else begin
            rank = 1'b0; 
        end
    end

endmodule