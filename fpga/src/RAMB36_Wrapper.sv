`timescale 1ns / 1ps

import Constants::*;

//////////////////////////////////////////////////////////////////////////////////
// Initialize BRAM Blocks for the XC7A35T (Cmod A7-35T)
// Wrapper module for 1 primitive RAMB36E1 to form a 36-bit wide by 1K deep block
// ID[16 bits] Price(0.0001 increment)[30 bits] Quantity[16 bits] Valid[1 bit] Buy/Sell[1 bit] Total[64 bits] (save 28 bits somehow?)
//////////////////////////////////////////////////////////////////////////////////

module RAMB36_Wrapper#(
    parameter bit INIT_VAL
)(
    input  logic                  clk,
    input  logic                  rst,
    input  logic                  en,
    input  logic                  wr_en,
    input  logic [ADDR_WIDTH-1:0] addr,
    input  logic [DATA_WIDTH-1:0] wr_data,
    output logic [DATA_WIDTH-1:0] rd_data
);

    RAMB36E1 #(
        // Address Collision Mode: "PERFORMANCE" or "DELAYED_WRITE"
        .RDADDR_COLLISION_HWCONFIG ("DELAYED_WRITE"),

        // Collision check: Values ("ALL", "WARNING_ONLY", "GENERATE_X_ONLY" or "NONE")
        .SIM_COLLISION_CHECK       ("ALL"),

        // DOA_REG, DOB_REG: Optional output register (0 or 1)
        .DOA_REG                   (0),
        .DOB_REG                   (0),

        // READ_WIDTH_A/B, WRITE_WIDTH_A/B: Read/write width per port
        .READ_WIDTH_A              (BLOCK_WIDTH),
        .WRITE_WIDTH_B             (BLOCK_WIDTH),

        // WriteMode: Value on output upon a write ("WRITE_FIRST", "READ_FIRST", or "NO_CHANGE")
        .WRITE_MODE_A              ("READ_FIRST"),
        .WRITE_MODE_B              ("READ_FIRST"),

        // RAM Mode: "SDP" or "TDP"
        .RAM_MODE                  ("TDP"),                             // Use Simple Dual Port mode for pipelined stages

        .INIT_FILE                 (INIT_VAL ? "ram_init_1.mem" : "NONE"),

        // Value during reset
        .SRVAL_A                   ({DATA_WIDTH{INIT_VAL}}),
        .SRVAL_B                   ({DATA_WIDTH{INIT_VAL}}),

        .SIM_COLLISION_CHECK       ("ALL")

    ) RAMB36E1_inst (
        // Port A Address/Control Signals: 16-bit (each) input: Port A address and control signals (read port when RAM_MODE="SDP")
        .ADDRARDADDR   ({(ADDR_BUS_WIDTH - ADDR_WIDTH - 5)'(0), addr, 5'b0}),     // 16-bit input: A port address/Read address
        .CLKARDCLK     (clk),                                                     // 1-bit input: A port clock/Read clock
        .ENARDEN       (en),                                                      // 1-bit input: A port enable/Read enable
        .RSTRAMARSTRAM (rst),                                                     // 1-bit input: A port set/reset

        // Port A Data: 16-bit (each) output: Port A data
        .DOADO         (rd_data[DATA_BITS-1 : 0]),                                // 32-bit output: A port data/LSB data
        .DOPADOP       (rd_data[BLOCK_WIDTH-1 : DATA_BITS]),                      // 4-bit output: A port parity/LSB parity

        // Port B Address/Control Signals: 16-bit (each) input: Port B address and control signals (write port when RAM_MODE="SDP")
        .ADDRBWRADDR   ({(ADDR_BUS_WIDTH - ADDR_WIDTH - 5)'(0), addr, 5'b0}),     // 16-bit input: B port address/Write address
        .CLKBWRCLK     (clk),                                                     // 1-bit input: B port clock/Write clock
        .ENBWREN       (en),                                                      // 1-bit input: B port enable/Write enable
        .RSTRAMB       (rst),                                                     // 1-bit input: B port register enable
        .WEBWE         ({8{wr_en}}),                                              // 4-bit input: B port write enable/Write enable

        // Port B Data: 16-bit (each) input: Port B data
        .DIBDI         (wr_data[DATA_BITS-1 : 0]),                                // 32-bit input: B port data/MSB data
        .DIPBDIP       (wr_data[BLOCK_WIDTH-1 : DATA_BITS])                       // 4-bit input: B port parity/MSB parity
    );

endmodule