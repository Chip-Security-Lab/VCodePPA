module multi_context_regfile #(
    parameter DW = 32,
    parameter AW = 3,
    parameter CTX_BITS = 3
)(
    input clk,
    input [CTX_BITS-1:0] ctx_sel,
    input wr_en,
    input [AW-1:0] addr,
    input [DW-1:0] din,
    output [DW-1:0] dout
);
reg [DW-1:0] ctx_bank [0:7][0:(1<<AW)-1]; // 8个上下文

always @(posedge clk) begin
    if (wr_en) ctx_bank[ctx_sel][addr] <= din;
end

assign dout = ctx_bank[ctx_sel][addr];
endmodule