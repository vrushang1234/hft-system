`timescale 1ns / 1ps

package Constants;
    
    typedef enum logic {INVALID, VALID} state_t;
    
    parameter ADDR_BUS_WIDTH = 16;                            // address input bus width

    parameter BLOCKS = 16;                                    // Number of BRAM Blocks to be initialized, equal to the depth of each priority queue

    parameter DATA_BITS   = 32;
    parameter PARITY_BITS = 4;
    parameter BLOCK_WIDTH  = DATA_BITS + PARITY_BITS;
  
    parameter DATA_WIDTH = BLOCK_WIDTH * 2;                     // Width of each priority queue item

    // 1-bit wide by 32K deep to 36-bit wide by 1K deep
    parameter ADDR_DEPTH = 1024 * BLOCK_WIDTH / 36;
    parameter ADDR_WIDTH = $clog2(ADDR_DEPTH);    
  
endpackage