//SystemVerilog
// 顶层模块
module counter_ismu #(
    parameter N = 8
)(
    input  wire         CLK,
    input  wire         nRST,
    input  wire [N-1:0] IRQ,
    input  wire         CLR_CNT,
    output reg  [N-1:0] IRQ_STATUS,
    output reg  [N-1:0][7:0] IRQ_COUNT
);
    // 内部信号
    reg  [N-1:0] IRQ_prev;
    wire [7:0]   increment_result;
    
    // 实例化计数器控制模块
    counter_controller #(
        .N(N)
    ) counter_ctrl_inst (
        .CLK(CLK),
        .nRST(nRST),
        .IRQ(IRQ),
        .IRQ_prev(IRQ_prev),
        .CLR_CNT(CLR_CNT),
        .IRQ_COUNT(IRQ_COUNT),
        .IRQ_STATUS(IRQ_STATUS),
        .increment_result(increment_result)
    );
    
    // 实例化并行前缀加法器模块
    parallel_prefix_adder adder_inst (
        .a(IRQ_COUNT[0]),  // 动态选择当前被处理的计数器值
        .b(8'h1),         // 增量值固定为1
        .sum(increment_result)
    );
    
endmodule

// 计数器控制模块
module counter_controller #(
    parameter N = 8
)(
    input  wire         CLK,
    input  wire         nRST,
    input  wire [N-1:0] IRQ,
    output reg  [N-1:0] IRQ_prev,
    input  wire         CLR_CNT,
    output reg  [N-1:0][7:0] IRQ_COUNT,
    output reg  [N-1:0] IRQ_STATUS,
    input  wire [7:0]   increment_result
);
    integer i;
    
    always @(posedge CLK or negedge nRST) begin
        if (!nRST) begin
            IRQ_prev <= {N{1'b0}};
            IRQ_STATUS <= {N{1'b0}};
            for (i = 0; i < N; i = i + 1)
                IRQ_COUNT[i] <= 8'h0;
        end else begin
            IRQ_prev <= IRQ;
            for (i = 0; i < N; i = i + 1) begin
                if (IRQ[i] & ~IRQ_prev[i]) begin
                    IRQ_STATUS[i] <= 1'b1;
                    if (IRQ_COUNT[i] < 8'hFF) begin
                        IRQ_COUNT[i] <= increment_result;
                    end
                end
                if (CLR_CNT) begin
                    IRQ_STATUS <= {N{1'b0}};
                    IRQ_COUNT[i] <= 8'h0;
                end
            end
        end
    end
    
endmodule

// 并行前缀加法器模块
module parallel_prefix_adder (
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire [7:0] sum
);
    // 内部信号声明
    wire [7:0] p_stage1, g_stage1;
    wire [7:0] p_stage2, g_stage2;
    wire [7:0] p_stage3, g_stage3;
    wire [7:0] p_stage4, g_stage4;
    wire [7:0] carry;
    
    // 第一阶段：生成初始的传播和生成信号
    assign p_stage1 = a ^ b;
    assign g_stage1 = a & b;
    
    // 第二阶段：2位组合
    // 偶数位
    assign p_stage2[0] = p_stage1[0];
    assign g_stage2[0] = g_stage1[0];
    assign p_stage2[2] = p_stage1[2];
    assign g_stage2[2] = g_stage1[2];
    assign p_stage2[4] = p_stage1[4];
    assign g_stage2[4] = g_stage1[4];
    assign p_stage2[6] = p_stage1[6];
    assign g_stage2[6] = g_stage1[6];
    
    // 奇数位
    assign p_stage2[1] = p_stage1[1] & p_stage1[0];
    assign g_stage2[1] = g_stage1[1] | (p_stage1[1] & g_stage1[0]);
    assign p_stage2[3] = p_stage1[3] & p_stage1[2];
    assign g_stage2[3] = g_stage1[3] | (p_stage1[3] & g_stage1[2]);
    assign p_stage2[5] = p_stage1[5] & p_stage1[4];
    assign g_stage2[5] = g_stage1[5] | (p_stage1[5] & g_stage1[4]);
    assign p_stage2[7] = p_stage1[7] & p_stage1[6];
    assign g_stage2[7] = g_stage1[7] | (p_stage1[7] & g_stage1[6]);
    
    // 第三阶段：4位组合
    // 保持位
    assign p_stage3[0] = p_stage2[0];
    assign g_stage3[0] = g_stage2[0];
    assign p_stage3[1] = p_stage2[1];
    assign g_stage3[1] = g_stage2[1];
    assign p_stage3[4] = p_stage2[4];
    assign g_stage3[4] = g_stage2[4];
    assign p_stage3[5] = p_stage2[5];
    assign g_stage3[5] = g_stage2[5];
    
    // 组合位
    assign p_stage3[2] = p_stage2[2] & p_stage2[0];
    assign g_stage3[2] = g_stage2[2] | (p_stage2[2] & g_stage2[0]);
    assign p_stage3[3] = p_stage2[3] & p_stage2[1];
    assign g_stage3[3] = g_stage2[3] | (p_stage2[3] & g_stage2[1]);
    assign p_stage3[6] = p_stage2[6] & p_stage2[4];
    assign g_stage3[6] = g_stage2[6] | (p_stage2[6] & g_stage2[4]);
    assign p_stage3[7] = p_stage2[7] & p_stage2[5];
    assign g_stage3[7] = g_stage2[7] | (p_stage2[7] & g_stage2[5]);
    
    // 第四阶段：8位组合
    // 保持位
    assign p_stage4[0] = p_stage3[0];
    assign g_stage4[0] = g_stage3[0];
    assign p_stage4[1] = p_stage3[1];
    assign g_stage4[1] = g_stage3[1];
    assign p_stage4[2] = p_stage3[2];
    assign g_stage4[2] = g_stage3[2];
    assign p_stage4[3] = p_stage3[3];
    assign g_stage4[3] = g_stage3[3];
    
    // 组合位
    assign p_stage4[4] = p_stage3[4] & p_stage3[0];
    assign g_stage4[4] = g_stage3[4] | (p_stage3[4] & g_stage3[0]);
    assign p_stage4[5] = p_stage3[5] & p_stage3[1];
    assign g_stage4[5] = g_stage3[5] | (p_stage3[5] & g_stage3[1]);
    assign p_stage4[6] = p_stage3[6] & p_stage3[2];
    assign g_stage4[6] = g_stage3[6] | (p_stage3[6] & g_stage3[2]);
    assign p_stage4[7] = p_stage3[7] & p_stage3[3];
    assign g_stage4[7] = g_stage3[7] | (p_stage3[7] & g_stage3[3]);
    
    // 生成进位
    assign carry[0] = 1'b0; // 初始进位为0
    assign carry[1] = g_stage4[0];
    assign carry[2] = g_stage4[1];
    assign carry[3] = g_stage4[2];
    assign carry[4] = g_stage4[3];
    assign carry[5] = g_stage4[4];
    assign carry[6] = g_stage4[5];
    assign carry[7] = g_stage4[6];
    
    // 计算最终和
    assign sum = p_stage1 ^ carry;
    
endmodule