//SystemVerilog
// SystemVerilog
module config_polarity_reset #(
    parameter CHANNELS = 4
)(
    input wire reset_in,
    input wire [CHANNELS-1:0] polarity_config,
    output wire [CHANNELS-1:0] reset_out
);
    // 使用位选择和连接操作符优化重置信号生成
    // 根据polarity_config选择性地复制或反转reset_in信号
    assign reset_out = ({CHANNELS{reset_in}} & polarity_config) | 
                       ({CHANNELS{~reset_in}} & ~polarity_config);
endmodule

// 优化的Kogge-Stone Adder实现 (8-bit)
module kogge_stone_adder (
    input [7:0] a,
    input [7:0] b,
    input cin,
    output [7:0] sum,
    output cout
);
    // 生成(G)和传播(P)信号
    wire [7:0] g0, p0;
    
    // 阶段0: 初始G和P信号生成
    assign g0 = a & b;
    assign p0 = a ^ b;
    
    // 优化的进位计算 - 使用阶段式计算减少关键路径
    
    // 阶段1: 计算距离为1的中间G和P
    wire [7:0] g1, p1;
    
    // 使用循环外的直接赋值提高代码清晰度
    assign g1[0] = g0[0];
    assign p1[0] = p0[0];
    
    generate
        genvar i;
        for (i = 1; i < 8; i = i + 1) begin: stage1_gen
            assign g1[i] = g0[i] | (p0[i] & g0[i-1]);
            assign p1[i] = p0[i] & p0[i-1];
        end
    endgenerate
    
    // 阶段2: 计算距离为2的中间G和P
    wire [7:0] g2, p2;
    
    // 保持前两位不变
    assign g2[1:0] = g1[1:0];
    assign p2[1:0] = p1[1:0];
    
    generate
        for (i = 2; i < 8; i = i + 1) begin: stage2_gen
            assign g2[i] = g1[i] | (p1[i] & g1[i-2]);
            assign p2[i] = p1[i] & p1[i-2];
        end
    endgenerate
    
    // 阶段3: 计算距离为4的中间G和P
    wire [7:0] g3, p3;
    
    // 优化赋值，使用位选择操作减少单独的赋值语句
    assign g3[3:0] = g2[3:0];
    assign p3[3:0] = p2[3:0];
    
    generate
        for (i = 4; i < 8; i = i + 1) begin: stage3_gen
            assign g3[i] = g2[i] | (p2[i] & g2[i-4]);
            assign p3[i] = p2[i] & p2[i-4];
        end
    endgenerate
    
    // 计算进位链
    wire [8:0] carries;
    assign carries[0] = cin;
    
    // 优化进位计算，利用前面计算的g3和p3
    generate
        for (i = 0; i < 8; i = i + 1) begin: carry_gen
            // 直接使用g3和p3减少中间变量和路径延迟
            assign carries[i+1] = g3[i] | (p3[i] & cin);
        end
    endgenerate
    
    // 计算和与进位输出
    assign sum = p0 ^ carries[7:0];
    assign cout = carries[8];
endmodule