//SystemVerilog
module sram_pipelined #(
    parameter DW = 64,
    parameter AW = 8
)(
    input clk,
    input ce,
    input we,
    input [AW-1:0] addr,
    input [DW-1:0] din,
    output reg [DW-1:0] dout
);

// Memory array
reg [DW-1:0] mem [0:(1<<AW)-1];
reg [DW-1:0] pipe_reg;

// Lookup table for address calculation
reg [AW-1:0] addr_lut [0:255];
reg [AW-1:0] addr_reg;

// Initialize lookup table
initial begin
    integer i;
    for (i = 0; i < 256; i = i + 1) begin
        addr_lut[i] = i;
    end
end

// Combined address calculation and memory access pipeline
always @(posedge clk) begin
    if (ce) begin
        // Address calculation using lookup table
        addr_reg <= addr_lut[addr];
        
        // Memory access
        if (we) mem[addr_reg] <= din;
        pipe_reg <= mem[addr_reg];
    end
    dout <= pipe_reg;  // 2-stage pipeline
end

endmodule