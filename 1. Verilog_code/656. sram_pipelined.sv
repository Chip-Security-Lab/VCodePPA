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

always @(posedge clk) begin
    if (ce) begin
        if (we) mem[addr] <= din;
        pipe_reg <= mem[addr];
    end
    dout <= pipe_reg;  // 2-stage pipeline
end
endmodule
