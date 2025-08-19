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

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dout <= 0;
        for (i=0; i<DEPTH; i=i+1) mem[i] <= 0;
    end else if (cs) begin
        if (we) mem[addr] <= din;
        dout <= mem[addr];
    end
end
endmodule