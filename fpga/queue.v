`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// A standard FIFO queue using BRAM
//////////////////////////////////////////////////////////////////////////////////


module queue #(
    parameter ADDR_WIDTH = 8,     //Configurations            
    parameter DATA_WIDTH = 32                   
    )(
    input clk,
    input push,
    input pop,
    input peek,
    input [DATA_WIDTH-1:0] wr_val,
    output reg [DATA_WIDTH-1:0] rd_val,
    output reg empty = 1'b1,
    output reg full = 1'b0
    );
    
    localparam DEPTH = (1 << ADDR_WIDTH); //Depth for # of memory locations (if address port = x bits, encode = 2^x)
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1]; //Memory Array :)
    
    // MSB is the lap value used to check if the queue is full or empty
    reg [ADDR_WIDTH:0] head_ext = 0;
    reg [ADDR_WIDTH:0] tail_ext = 0;
    
    wire [ADDR_WIDTH-1:0] head;
    wire [ADDR_WIDTH-1:0] tail;
    
    assign head = head_ext[ADDR_WIDTH-1:0];
    assign tail = tail_ext[ADDR_WIDTH-1:0];
    
    // function triggers
    reg trig_push = 1'b0;
    reg trig_pop = 1'b0;
    reg trig_peek = 1'b0;
    
    // initial begin
        // Initialize from a hexadecimal file named "mem_init.mem" for simulation (not synthesizable)
        // $readmemh("mem_init.mem", mem); 
        // $readmemh("mem_init.mem", mem, 0, 127); 
    // end
    
    always @(posedge push)
        trig_push = 1'b1;
    always @(posedge pop)
        trig_pop = 1'b1;
    always @(posedge peek)
        trig_peek = 1'b1;
        
    always @(posedge clk) begin
        if (head == tail) begin
            empty = (head_ext[ADDR_WIDTH] == tail_ext[ADDR_WIDTH]);
            full = ~empty;
        end else begin
            empty = 1'b0;
            full = 1'b0;
        end
        
        if (~full && trig_push) begin
            trig_push = 1'b0;
            mem[tail] = wr_val;
            tail_ext = tail_ext + 1;
        end
             
        if (~empty && trig_pop) begin
            trig_pop = 1'b0;
            rd_val = mem[head];
            mem[head] = {DATA_WIDTH{1'b0}};
            head_ext = head_ext + 1;
        end
        if (~empty && trig_peek) begin
            trig_peek = 1'b0;
            rd_val = mem[head];
        end
        
        
        
    end
    
endmodule
