`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// A standard FIFO queue using BRAM
//////////////////////////////////////////////////////////////////////////////////


module queue #(
    parameter ADDR_WIDTH = 8,     //Configurations            
    parameter DATA_WIDTH = 32                   
    )(
    input clk,
    input write,
    input pop,
    input peek,
    input [DATA_WIDTH-1:0] write_value,
    output reg [DATA_WIDTH-1:0] read_value
    );
    
    localparam DEPTH = (1 << ADDR_WIDTH); //Depth for # of memory locations (if address port = x bits, encode = 2^x)
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1]; //Memory Array :)
    
    reg [ADDR_WIDTH-1:0] head = 0;
    reg [ADDR_WIDTH-1:0] tail = 0;
    
    // initial begin
        // Initialize from a hexadecimal file named "mem_init.mem" for simulation (not synthesizable)
        // $readmemh("mem_init.mem", mem); 
        // $readmemh("mem_init.mem", mem, 0, 127); 
    // end
    
    always @(posedge clk) begin
        if (~(head == tail) && (pop ^ peek)) begin
            read_value <= mem[head];
            if (pop) begin
                mem[head] <= {DATA_WIDTH{1'b0}};
                head <= head + 1;
            end
        end
        if (write) begin
            mem[tail] <= write_value;
            tail <= tail + 1;
        end
    end
endmodule
