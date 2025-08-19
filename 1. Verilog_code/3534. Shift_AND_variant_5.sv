//SystemVerilog
//IEEE 1364-2005 Verilog

// 顶层模块 - 带流水线的移位与操作处理器
module Shift_AND (
    input wire clk,          // 时钟输入
    input wire rst_n,        // 复位信号，低电平有效
    input wire [2:0] shift_ctrl,
    input wire [31:0] vec,
    output wire [31:0] out
);
    // 内部流水线寄存器
    reg [2:0] shift_ctrl_r1;
    reg [31:0] vec_r1;
    
    // 阶段间数据传递信号
    wire [31:0] shifted_mask;
    reg [31:0] shifted_mask_r1;
    
    // 第一阶段：输入寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_ctrl_r1 <= 3'b0;
            vec_r1 <= 32'b0;
        end else begin
            shift_ctrl_r1 <= shift_ctrl;
            vec_r1 <= vec;
        end
    end
    
    // 第二阶段：掩码生成
    ShiftMaskGenerator mask_gen (
        .shift_amount(shift_ctrl_r1),
        .shifted_mask(shifted_mask)
    );
    
    // 第三阶段：掩码寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shifted_mask_r1 <= 32'hFFFFFFFF;
        end else begin
            shifted_mask_r1 <= shifted_mask;
        end
    end
    
    // 第四阶段：位运算处理
    BitwiseOperation bit_op (
        .operand_a(vec_r1),
        .operand_b(shifted_mask_r1),
        .result(out)
    );
endmodule

// 优化的移位掩码生成器 - 使用参数化设计提高可配置性
module ShiftMaskGenerator (
    input wire [2:0] shift_amount,
    output wire [31:0] shifted_mask
);
    // 参数化设计
    parameter MASK_WIDTH = 32;
    parameter FULL_MASK = {MASK_WIDTH{1'b1}}; // 32'hFFFFFFFF
    
    // 掩码生成逻辑，分解为较小的移位操作以减少逻辑深度
    wire [31:0] shift_stage1;
    
    // 第一移位阶段 - 处理低位移位
    assign shift_stage1 = (shift_amount[0]) ? (FULL_MASK << 1) : FULL_MASK;
    
    // 第二移位阶段 - 处理高位移位，逐步移位减少关键路径
    assign shifted_mask = (shift_amount[2:1] == 2'b00) ? shift_stage1 :
                        (shift_amount[2:1] == 2'b01) ? (shift_stage1 << 2) :
                        (shift_amount[2:1] == 2'b10) ? (shift_stage1 << 4) :
                                                    (shift_stage1 << 6);
endmodule

// 高效位操作模块 - 使用明确的数据流
module BitwiseOperation (
    input wire [31:0] operand_a,
    input wire [31:0] operand_b,
    output wire [31:0] result
);
    // 分段处理，提高并行性
    wire [7:0] result_byte0, result_byte1, result_byte2, result_byte3;
    
    // 按字节并行处理与操作，减少关键路径
    assign result_byte0 = operand_a[7:0] & operand_b[7:0];
    assign result_byte1 = operand_a[15:8] & operand_b[15:8];
    assign result_byte2 = operand_a[23:16] & operand_b[23:16];
    assign result_byte3 = operand_a[31:24] & operand_b[31:24];
    
    // 合并结果
    assign result = {result_byte3, result_byte2, result_byte1, result_byte0};
endmodule