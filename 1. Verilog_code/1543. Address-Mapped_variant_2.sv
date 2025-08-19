//SystemVerilog
`timescale 1ns / 1ps
/* IEEE 1364-2005 Verilog Standard */

module address_shadow_reg #(
    parameter WIDTH = 32,
    parameter ADDR_WIDTH = 4,
    parameter BASE_ADDR = 4'h0
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire write_en,
    input wire read_en,
    output reg [WIDTH-1:0] data_out,
    output reg [WIDTH-1:0] shadow_data
);
    // Optimized address decoding using localparam and single-bit comparison
    localparam SHADOW_ADDR = BASE_ADDR + 1'b1;
    
    // Efficient address comparison - reduces comparison chain
    wire addr_is_base = (addr == BASE_ADDR);
    wire addr_is_shadow = (addr == SHADOW_ADDR);
    
    // Combined write signals to reduce logic depth
    wire write_to_main = write_en & addr_is_base;
    wire write_to_shadow = write_en & (addr_is_shadow | addr_is_base);
    
    // Main register logic with optimized conditional structure
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out <= {WIDTH{1'b0}};
        else if (write_to_main)
            data_out <= data_in;
    end
    
    // Shadow register with address-mapped access
    // Optimized priority logic for shadow updates
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shadow_data <= {WIDTH{1'b0}};
        else if (write_en) begin
            if (addr_is_shadow)
                shadow_data <= data_in;
            else if (addr_is_base)
                shadow_data <= data_in; // Direct forwarding instead of using data_out
        end
    end
endmodule