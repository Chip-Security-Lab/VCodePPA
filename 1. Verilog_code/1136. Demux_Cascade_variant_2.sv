//SystemVerilog
//IEEE 1364-2005 Verilog
module Demux_Cascade #(parameter DW=8, DEPTH=2) (
    input wire clk,
    input wire [DW-1:0] data_in,
    input wire [$clog2(DEPTH+1)-1:0] addr,
    output reg [DEPTH:0][DW-1:0] data_out
);
    // Intermediate pipeline registers for data path segmentation
    reg [DW-1:0] data_in_reg;
    reg [$clog2(DEPTH+1)-1:0] addr_reg;
    
    // First pipeline stage - input registration
    always @(posedge clk) begin
        data_in_reg <= data_in;
        addr_reg <= addr;
    end
    
    // Second pipeline stage - demux logic
    always @(posedge clk) begin
        // Default values - clear all outputs
        for (int i = 0; i <= DEPTH; i = i + 1) begin
            data_out[i] <= {DW{1'b0}};
        end
        
        // Direct data routing based on address
        if (addr_reg <= DEPTH) begin
            data_out[addr_reg] <= data_in_reg;
        end
    end
endmodule