//SystemVerilog
module Demux_LUT #(
    parameter DW = 8,          // Data width
    parameter AW = 3,          // Address width
    parameter LUT_SIZE = 8     // Lookup table size
)(
    input  wire                  clk,          // Clock signal (added for pipelining)
    input  wire                  rst_n,        // Reset signal (added for pipelining)
    input  wire [DW-1:0]         data_in,      // Input data
    input  wire [AW-1:0]         addr,         // Address input
    input  wire [LUT_SIZE-1:0][AW-1:0] remap_table, // Address remapping table
    output reg  [LUT_SIZE-1:0][DW-1:0] data_out     // Demuxed output data
);
    // Pipeline stage 1: Address lookup and validation
    reg [AW-1:0] addr_stage1;
    reg [DW-1:0] data_stage1;
    reg [AW-1:0] remapped_addr_stage1;
    reg          addr_valid_stage1;
    
    // Pipeline stage 2: Output preparation
    reg [AW-1:0] remapped_addr_stage2;
    reg [DW-1:0] data_stage2;
    reg          addr_valid_stage2;
    
    // Stage 1: Address lookup and validation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage1 <= {AW{1'b0}};
            data_stage1 <= {DW{1'b0}};
            remapped_addr_stage1 <= {AW{1'b0}};
            addr_valid_stage1 <= 1'b0;
        end else begin
            addr_stage1 <= addr;
            data_stage1 <= data_in;
            remapped_addr_stage1 <= remap_table[addr];
            addr_valid_stage1 <= (remap_table[addr] < LUT_SIZE);
        end
    end
    
    // Stage 2: Output preparation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            remapped_addr_stage2 <= {AW{1'b0}};
            data_stage2 <= {DW{1'b0}};
            addr_valid_stage2 <= 1'b0;
        end else begin
            remapped_addr_stage2 <= remapped_addr_stage1;
            data_stage2 <= data_stage1;
            addr_valid_stage2 <= addr_valid_stage1;
        end
    end
    
    // Final output demux stage
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all outputs
            for (i = 0; i < LUT_SIZE; i = i + 1) begin
                data_out[i] <= {DW{1'b0}};
            end
        end else begin
            // Default: clear all outputs first
            for (i = 0; i < LUT_SIZE; i = i + 1) begin
                data_out[i] <= {DW{1'b0}};
            end
            
            // Set the active output if address is valid
            if (addr_valid_stage2) begin
                data_out[remapped_addr_stage2] <= data_stage2;
            end
        end
    end
    
endmodule