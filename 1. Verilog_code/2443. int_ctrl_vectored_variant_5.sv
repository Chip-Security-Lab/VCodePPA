//SystemVerilog
module int_ctrl_vectored #(parameter VEC_W=16)(
    input  wire                clk,
    input  wire                rst,
    input  wire [VEC_W-1:0]    int_in,
    input  wire [VEC_W-1:0]    mask_reg,
    output reg  [VEC_W-1:0]    int_out
);
    // 使用条件运算符替代always块中的if-else结构
    always @(posedge clk)
        int_out <= rst ? {VEC_W{1'b0}} : (int_out | int_in) & mask_reg;
        
endmodule