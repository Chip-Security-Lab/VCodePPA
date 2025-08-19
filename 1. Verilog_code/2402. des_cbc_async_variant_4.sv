//SystemVerilog - IEEE 1364-2005
module des_cbc_async (
    input wire [63:0] din,
    input wire [63:0] iv,
    input wire [55:0] key,
    output wire [63:0] dout
);
    // 内部连线声明
    wire [63:0] din_xor_iv;
    wire [31:0] left_half, right_half;
    wire [31:0] feistel_result;
    reg [63:0] dout_reg;
    
    // 第一级：输入与初始向量的XOR运算
    assign din_xor_iv = din ^ iv;
    
    // 第二级：分离左右半部分
    assign left_half = din_xor_iv[63:32];
    assign right_half = din_xor_iv[31:0];
    
    // 第三级：执行Feistel网络变换
    assign feistel_result = left_half ^ key[31:0];
    
    // 第四级：构建输出数据路径
    always @(*) begin
        // 重组输出数据，提高可读性
        dout_reg[63:48] = right_half[15:0];
        dout_reg[47:16] = feistel_result;
        dout_reg[15:0] = right_half[31:16];
    end
    
    // 输出赋值
    assign dout = dout_reg;
    
endmodule