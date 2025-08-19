//SystemVerilog
module decoder_sync_reg (
    input clk, rst_n, en,
    input [3:0] addr,
    output reg [15:0] decoded
);
    // 先计算组合逻辑结果，将寄存器移到组合逻辑之后
    reg [3:0] addr_reg;
    wire [15:0] decoded_comb;
    
    // 注册输入
    always @(posedge clk or negedge rst_n)
        if (!rst_n) addr_reg <= 4'h0;
        else if (en) addr_reg <= addr;
    
    // 组合逻辑解码部分 - 使用桶形移位器结构实现
    // 桶形移位器通过多路复用器层级实现
    wire [15:0] level0, level1, level2, level3;
    
    // 基本的"1"位置
    assign level0 = 16'h0001;
    
    // 第一级移位 - 移动0或1位
    assign level1 = addr_reg[0] ? {level0[14:0], level0[15]} : level0;
    
    // 第二级移位 - 移动0或2位
    assign level2 = addr_reg[1] ? {level1[13:0], level1[15:14]} : level1;
    
    // 第三级移位 - 移动0或4位
    assign level3 = addr_reg[2] ? {level2[11:0], level2[15:12]} : level2;
    
    // 第四级移位 - 移动0或8位
    assign decoded_comb = addr_reg[3] ? {level3[7:0], level3[15:8]} : level3;
    
    // 输出寄存器
    always @(posedge clk or negedge rst_n)
        if (!rst_n) decoded <= 16'h0;
        else if (en) decoded <= decoded_comb;
endmodule