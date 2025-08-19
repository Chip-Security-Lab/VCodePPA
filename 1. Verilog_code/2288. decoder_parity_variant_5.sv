//SystemVerilog
module decoder_parity (
    input [4:0] addr_in,  // [4]=parity
    output reg valid,
    output [7:0] decoded
);
    wire [3:0] addr = addr_in[3:0];
    
    // 优化奇偶校验计算，使用异或归约运算符
    wire computed_parity = ^addr;
    
    // 简化验证逻辑，使用异或比较
    always @(*) begin
        valid = ~(computed_parity ^ addr_in[4]);
    end
    
    // 使用桶形移位器结构实现移位操作
    // 第一级移位 - 移动0或1位
    wire [7:0] level1;
    assign level1 = addr[0] ? {7'b0000000, 1'b1} : {1'b1, 7'b0000000};
    
    // 第二级移位 - 移动0或2位
    wire [7:0] level2;
    assign level2 = addr[1] ? {level1[5:0], level1[7:6]} : level1;
    
    // 第三级移位 - 移动0或4位
    wire [7:0] level3;
    assign level3 = addr[2] ? {level2[3:0], level2[7:4]} : level2;
    
    // 最后应用valid信号
    assign decoded = valid ? level3 : 8'h0;
endmodule