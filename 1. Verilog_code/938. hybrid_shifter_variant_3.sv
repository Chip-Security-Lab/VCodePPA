//SystemVerilog
module hybrid_shifter #(
    parameter DATA_W = 16,
    parameter SHIFT_W = 4
)(
    input wire [DATA_W-1:0] din,
    input wire [SHIFT_W-1:0] shift,
    input wire dir,  // 0-left, 1-right
    input wire mode,  // 0-logical, 1-arithmetic
    output reg [DATA_W-1:0] dout
);
    // 分段处理:
    // 第一级: 通过寄存器捕获输入数据和控制信号
    reg [DATA_W-1:0] din_reg;
    reg [SHIFT_W-1:0] shift_reg;
    reg dir_reg, mode_reg;
    
    always @(*) begin
        din_reg = din;
        shift_reg = shift;
        dir_reg = dir;
        mode_reg = mode;
    end
    
    // 第二级: 左移数据路径
    wire [DATA_W-1:0] left_shift_result;
    assign left_shift_result = din_reg << shift_reg;
    
    // 第二级: 右移数据路径 - 逻辑右移
    wire [DATA_W-1:0] logical_right_shift;
    assign logical_right_shift = din_reg >> shift_reg;
    
    // 第二级: 右移数据路径 - 算术右移
    wire [DATA_W-1:0] arithmetic_right_shift;
    wire sign_bit = din_reg[DATA_W-1];
    
    // 计算算术右移 - 根据数据位宽动态生成符号扩展
    wire [DATA_W-1:0] sign_extended;
    assign sign_extended = {DATA_W{sign_bit}};
    
    // 根据移位值生成掩码并与符号扩展结合
    wire [DATA_W-1:0] shift_mask;
    assign shift_mask = (~({DATA_W{1'b1}} << (DATA_W - shift_reg))) & {DATA_W{shift_reg != 0}};
    
    // 计算最终的算术右移结果
    assign arithmetic_right_shift = (din_reg >> shift_reg) | (sign_extended & shift_mask);
    
    // 第三级: 根据模式选择右移类型
    wire [DATA_W-1:0] right_shift_result;
    assign right_shift_result = mode_reg ? arithmetic_right_shift : logical_right_shift;
    
    // 最终级: 根据方向选择左移或右移结果
    always @(*) begin
        dout = dir_reg ? right_shift_result : left_shift_result;
    end

endmodule