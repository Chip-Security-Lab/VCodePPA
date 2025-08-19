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
reg [DW-1:0] mem [0:(1<<AW)-1];
reg [DW-1:0] pipe_reg;
reg [AW-1:0] addr_reg;
reg [AW-1:0] addr_reg2;

always @(posedge clk) begin
    if (ce) begin
        addr_reg <= addr;
        addr_reg2 <= addr_reg;
        if (we) mem[addr] <= din;
        pipe_reg <= mem[addr_reg2];
    end
    dout <= pipe_reg;  // 3-stage pipeline
end
endmodule