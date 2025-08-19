//SystemVerilog
module Hybrid_NAND(
    input [1:0] ctrl,
    input [7:0] base,
    output reg [7:0] res
);
    // 第一级流水线：计算阶段
    reg [3:0] shift_bits;      // 移位位数（优化后直接计算位数而非字节数）
    reg [7:0] computation_mask; // 优化后的掩码计算

    // 第二级流水线：逻辑操作阶段
    reg [7:0] masked_data;
    reg [7:0] result_data;

    // 数据流路径优化与分段
    always @(*) begin
        // 第一级：计算阶段 - 优化移位量直接映射
        case(ctrl)
            2'b00: shift_bits = 4'd0;
            2'b01: shift_bits = 4'd4;
            2'b10: shift_bits = 4'd8; // 注意这会溢出到0
            2'b11: shift_bits = 4'd12; // 注意这会溢出到4
        endcase
        
        // 计算掩码 - 使用参数化方法避免动态移位
        case(shift_bits)
            4'd0:  computation_mask = 8'h0F;
            4'd4:  computation_mask = 8'hF0;
            4'd8:  computation_mask = 8'h0F; // 溢出处理
            4'd12: computation_mask = 8'hF0; // 溢出处理
            default: computation_mask = 8'h0F;
        endcase
        
        // 第二级：逻辑操作阶段
        masked_data = base & computation_mask;
        result_data = ~masked_data;
        
        // 最终输出
        res = result_data;
    end
endmodule