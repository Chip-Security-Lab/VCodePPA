//SystemVerilog
module parity_gen #(parameter WIDTH=8, POS="LSB") (
    input [WIDTH-1:0] data_in,
    output reg [WIDTH:0] data_out
);

    wire [WIDTH-1:0] product;
    wire [(WIDTH/2)-1:0] a_high, a_low, b_high, b_low;
    wire [WIDTH-1:0] z0, z1, z2;
    wire [(WIDTH/2):0] a_sum, b_sum;
    wire [WIDTH-1:0] z1_adjusted;
    wire parity_bit;
    
    // 将输入数据分为高低两部分用于Karatsuba乘法
    assign a_high = data_in[WIDTH-1:WIDTH/2];
    assign a_low = data_in[(WIDTH/2)-1:0];
    assign b_high = 4'b0101; // 使用常数作为乘数以保持功能简单
    assign b_low = 4'b1010;
    
    // Karatsuba算法所需的中间值
    assign a_sum = a_high + a_low;
    assign b_sum = b_high + b_low;
    
    // 递归乘法计算
    // 对于8位宽度，这些是4位乘法
    assign z0 = a_low * b_low;
    assign z2 = a_high * b_high;
    assign z1 = (a_sum * b_sum) - z2 - z0;
    
    // 使用桶形移位器结构实现z1的移位操作
    // 首先实现(WIDTH/2)位的移位，对于WIDTH=8，这里是4位移位
    wire [WIDTH-1:0] z1_shift_stage1;
    
    // 桶形移位器第一级 - 固定移位4位
    assign z1_shift_stage1 = {z1[(WIDTH/2)-1:0], {(WIDTH/2){1'b0}}};
    
    // 最终赋值给z1_adjusted
    assign z1_adjusted = z1_shift_stage1;
    
    // 使用桶形移位器结构实现z2的移位操作
    // 为z2实现WIDTH位的移位，对于WIDTH=8，这里是8位移位
    wire [2*WIDTH-1:0] z2_extended = {z2, {WIDTH{1'b0}}};
    wire [WIDTH-1:0] z2_shifted = z2_extended[2*WIDTH-1:WIDTH];
    
    // 计算最终乘积，使用位拼接代替位移
    assign product = z2_shifted | z1_adjusted | z0;
    
    // 计算奇偶校验位
    assign parity_bit = ^product;
    
    // 保持与原始模块相同的输出逻辑
    always @(*) begin
        if (POS == "MSB") 
            data_out = {parity_bit, product};
        else
            data_out = {product, parity_bit};
    end
endmodule