module sram_parity #(
    parameter DATA_BITS = 8
)(
    input clk,
    input we,
    input [3:0] addr,
    input [DATA_BITS-1:0] din,
    output [DATA_BITS:0] dout  // [DATA_BITS] is parity
);
localparam TOTAL_BITS = DATA_BITS + 1;
reg [TOTAL_BITS-1:0] mem [0:15];
wire parity_in = ^din;

always @(posedge clk) begin
    if (we) mem[addr] <= {parity_in, din};
end

assign dout = mem[addr];
endmodule
