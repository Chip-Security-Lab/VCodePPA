//SystemVerilog
//IEEE 1364-2005 Verilog
// 顶层模块
module param_wide_xnor #(
    parameter WIDTH = 16
)(
    input  wire [WIDTH-1:0] A, 
    input  wire [WIDTH-1:0] B,
    output wire [WIDTH-1:0] Y
);

    wire [WIDTH-1:0] diff1, diff2;
    
    // 实例化第一个并行前缀减法器子模块: A - B
    parallel_prefix_subtractor #(
        .WIDTH(WIDTH)
    ) sub_a_minus_b (
        .minuend(A),
        .subtrahend(B),
        .difference(diff1)
    );
    
    // 实例化第二个并行前缀减法器子模块: B - A
    parallel_prefix_subtractor #(
        .WIDTH(WIDTH)
    ) sub_b_minus_a (
        .minuend(B),
        .subtrahend(A),
        .difference(diff2)
    );
    
    // 实例化XNOR逻辑子模块
    xnor_logic #(
        .WIDTH(WIDTH)
    ) xnor_result (
        .diff1(diff1),
        .diff2(diff2),
        .result(Y)
    );
    
endmodule

// 并行前缀减法器子模块
module parallel_prefix_subtractor #(
    parameter WIDTH = 16
)(
    input  wire [WIDTH-1:0] minuend,
    input  wire [WIDTH-1:0] subtrahend,
    output wire [WIDTH-1:0] difference
);
    
    // 定义前缀计算所需的信号
    wire [WIDTH-1:0] P; // 传播信号
    wire [WIDTH-1:0] G; // 生成信号
    wire [WIDTH:0] borrow; // 借位信号，多一位用于初始借位

    // 初始化借位为0
    assign borrow[0] = 1'b0;
    
    // 第一阶段：生成P和G信号
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_pg_signals
            assign P[i] = minuend[i] ^ subtrahend[i]; // 传播信号
            assign G[i] = ~minuend[i] & subtrahend[i]; // 生成信号（当被减数小于减数时产生借位）
        end
    endgenerate
    
    // 第二阶段：对于8位实现特化的并行前缀树
    generate
        if (WIDTH == 8) begin : parallel_8bit
            // 计算第一级前缀
            wire [7:0] G_L1, P_L1;
            
            // 第一级前缀计算
            assign G_L1[0] = G[0];
            assign P_L1[0] = P[0];
            
            assign G_L1[1] = G[1] | (P[1] & G[0]);
            assign P_L1[1] = P[1] & P[0];
            
            assign G_L1[2] = G[2];
            assign P_L1[2] = P[2];
            
            assign G_L1[3] = G[3] | (P[3] & G[2]);
            assign P_L1[3] = P[3] & P[2];
            
            assign G_L1[4] = G[4];
            assign P_L1[4] = P[4];
            
            assign G_L1[5] = G[5] | (P[5] & G[4]);
            assign P_L1[5] = P[5] & P[4];
            
            assign G_L1[6] = G[6];
            assign P_L1[6] = P[6];
            
            assign G_L1[7] = G[7] | (P[7] & G[6]);
            assign P_L1[7] = P[7] & P[6];
            
            // 第二级前缀计算
            wire [7:0] G_L2, P_L2;
            
            assign G_L2[0] = G_L1[0];
            assign P_L2[0] = P_L1[0];
            
            assign G_L2[1] = G_L1[1];
            assign P_L2[1] = P_L1[1];
            
            assign G_L2[2] = G_L1[2] | (P_L1[2] & G_L1[0]);
            assign P_L2[2] = P_L1[2] & P_L1[0];
            
            assign G_L2[3] = G_L1[3] | (P_L1[3] & G_L1[1]);
            assign P_L2[3] = P_L1[3] & P_L1[1];
            
            assign G_L2[4] = G_L1[4] | (P_L1[4] & G_L1[2]);
            assign P_L2[4] = P_L1[4] & P_L1[2];
            
            assign G_L2[5] = G_L1[5] | (P_L1[5] & G_L1[3]);
            assign P_L2[5] = P_L1[5] & P_L1[3];
            
            assign G_L2[6] = G_L1[6] | (P_L1[6] & G_L1[4]);
            assign P_L2[6] = P_L1[6] & P_L1[4];
            
            assign G_L2[7] = G_L1[7] | (P_L1[7] & G_L1[5]);
            assign P_L2[7] = P_L1[7] & P_L1[5];
            
            // 第三级前缀计算
            wire [7:0] G_L3, P_L3;
            
            assign G_L3[0] = G_L2[0];
            assign P_L3[0] = P_L2[0];
            
            assign G_L3[1] = G_L2[1];
            assign P_L3[1] = P_L2[1];
            
            assign G_L3[2] = G_L2[2];
            assign P_L3[2] = P_L2[2];
            
            assign G_L3[3] = G_L2[3];
            assign P_L3[3] = P_L2[3];
            
            assign G_L3[4] = G_L2[4] | (P_L2[4] & G_L2[0]);
            assign P_L3[4] = P_L2[4] & P_L2[0];
            
            assign G_L3[5] = G_L2[5] | (P_L2[5] & G_L2[1]);
            assign P_L3[5] = P_L2[5] & P_L2[1];
            
            assign G_L3[6] = G_L2[6] | (P_L2[6] & G_L2[2]);
            assign P_L3[6] = P_L2[6] & P_L2[2];
            
            assign G_L3[7] = G_L2[7] | (P_L2[7] & G_L2[3]);
            assign P_L3[7] = P_L2[7] & P_L2[3];
            
            // 计算所有借位
            assign borrow[1] = G_L3[0];
            assign borrow[2] = G_L3[1];
            assign borrow[3] = G_L3[2];
            assign borrow[4] = G_L3[3];
            assign borrow[5] = G_L3[4];
            assign borrow[6] = G_L3[5];
            assign borrow[7] = G_L3[6];
            assign borrow[8] = G_L3[7];
        end
        else begin : default_ripple
            // 对于非8位宽度，采用简化的借位计算
            for (i = 0; i < WIDTH; i = i + 1) begin : gen_borrow
                assign borrow[i+1] = G[i] | (P[i] & borrow[i]);
            end
        end
    endgenerate
    
    // 第三阶段：计算差值
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_difference
            assign difference[i] = P[i] ^ borrow[i]; // 差 = P ⊕ 借位
        end
    endgenerate
    
endmodule

// XNOR逻辑子模块
module xnor_logic #(
    parameter WIDTH = 16
)(
    input  wire [WIDTH-1:0] diff1,
    input  wire [WIDTH-1:0] diff2,
    output wire [WIDTH-1:0] result
);
    
    // XNOR结果 - 当输入相同时为1，不同时为0
    // 通过两次减法的结果可以确定输入是否相同
    assign result = ~(diff1 | diff2);
    
endmodule