//SystemVerilog
module NOR2 #(parameter W=8)(
    input  [W-1:0] a, 
    input  [W-1:0] b, 
    output [W-1:0] y
);
    // 使用条件反相减法器算法实现NOR功能
    
    // 中间变量声明
    wire [W-1:0] not_a;
    wire [W-1:0] not_b;
    wire [W:0] borrow;
    reg [W-1:0] result;
    
    // 反相计算
    assign not_a = ~a;
    assign not_b = ~b;
    
    // 初始借位设置
    assign borrow[0] = 1'b0;
    
    // 优化的减法器实现
    genvar i;
    generate
        for (i = 0; i < W; i = i + 1) begin : gen_subtractor
            // 第一级条件: 计算位异或结果
            wire bit_xor;
            assign bit_xor = not_a[i] ^ not_b[i];
            
            // 第二级条件: 计算当前位结果
            assign result[i] = bit_xor ^ borrow[i];
            
            // 第三级条件: 计算借位逻辑
            wire borrow_condition1, borrow_condition2;
            assign borrow_condition1 = ~not_a[i] & not_b[i];
            assign borrow_condition2 = borrow[i] & ~bit_xor;
            assign borrow[i+1] = borrow_condition1 | borrow_condition2;
        end
    endgenerate
    
    // 输出赋值
    assign y = result;
    
endmodule