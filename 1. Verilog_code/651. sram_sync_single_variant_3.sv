//SystemVerilog
module sram_sync_single #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4,
    parameter DEPTH = 16
)(
    input clk,
    input rst_n,
    input cs,
    input we,
    input [ADDR_WIDTH-1:0] addr,
    input [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout
);

reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
integer i;

// Parallel prefix subtractor signals
wire [DATA_WIDTH-1:0] sub_result;
wire [DATA_WIDTH:0] carry_chain;
wire [DATA_WIDTH-1:0] prop;
wire [DATA_WIDTH-1:0] gen;

// Generate and propagate signals
assign gen = din & ~mem[addr];
assign prop = din ^ ~mem[addr];

// Parallel prefix carry computation
assign carry_chain[0] = 1'b1;
genvar j;
generate
    for (j = 0; j < DATA_WIDTH; j = j + 1) begin : carry_chain_gen
        assign carry_chain[j+1] = gen[j] | (prop[j] & carry_chain[j]);
    end
endgenerate

// Final subtraction result
assign sub_result = prop ^ carry_chain[DATA_WIDTH-1:0];

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dout <= 0;
        i = 0;
        while (i < DEPTH) begin
            mem[i] <= 0;
            i = i + 1;
        end
    end else if (cs) begin
        if (we) mem[addr] <= din;
        dout <= sub_result;
    end
end

endmodule