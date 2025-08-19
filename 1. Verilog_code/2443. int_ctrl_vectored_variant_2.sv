//SystemVerilog
/* IEEE 1364-2005 */
module int_ctrl_vectored #(
    parameter VEC_W = 16
)(
    input                  clk,
    input                  rst,
    input  [VEC_W-1:0]     int_in,
    input  [VEC_W-1:0]     mask_reg,
    output [VEC_W-1:0]     int_out
);
    // 中间信号，使用条件求和减法算法实现
    reg  [VEC_W-1:0] pending_reg;
    wire [VEC_W-1:0] masked_int;
    wire [VEC_W-1:0] next_pending;
    wire [VEC_W-1:0] ones_complement;
    wire             carry_in;
    wire [VEC_W:0]   sum_with_carry;
    
    // 预先计算与掩码的相关操作
    assign masked_int = int_in & mask_reg;
    
    // 条件求和减法器实现 (A + (~B) + 1 = A - B)
    // 这里我们计算 pending_reg + masked_int，但使用条件求和的方式
    assign ones_complement = ~masked_int;
    assign carry_in = 1'b1; // 用于二进制补码
    
    assign sum_with_carry = {1'b0, pending_reg} + {1'b0, ones_complement} + {{VEC_W{1'b0}}, carry_in};
    assign next_pending = sum_with_carry[VEC_W-1:0];
    
    // 寄存器更新逻辑
    always @(posedge clk) begin
        if (rst) begin
            pending_reg <= {VEC_W{1'b0}};
        end else begin
            pending_reg <= next_pending;
        end
    end
    
    // 输出逻辑
    assign int_out = pending_reg;
    
endmodule