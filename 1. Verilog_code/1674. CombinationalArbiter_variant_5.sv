//SystemVerilog
module CombinationalArbiter #(parameter N=4) (
    input [N-1:0] req,
    output [N-1:0] grant
);

wire [N-1:0] mask;
wire [N-1:0] borrow;
wire [N-1:0] diff;

// 优化后的借位减法器实现
assign {borrow[0], diff[0]} = {1'b0, req[0]} - 1'b1;
genvar i;
generate
    for (i = 1; i < N; i = i + 1) begin : SUB_GEN
        assign {borrow[i], diff[i]} = {borrow[i-1], req[i]} - 1'b0;
    end
endgenerate

// 优化后的掩码和授权逻辑
assign mask = diff;
assign grant = req & ~mask;

endmodule