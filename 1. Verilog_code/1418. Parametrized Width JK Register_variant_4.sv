//SystemVerilog
module param_jk_register #(
    parameter WIDTH = 4
) (
    input wire clk,
    input wire [WIDTH-1:0] j,
    input wire [WIDTH-1:0] k,
    output reg [WIDTH-1:0] q
);
    integer i;
    wire [WIDTH-1:0] next_q;
    // 内部信号用于Kogge-Stone加法器
    wire [WIDTH-1:0] p_stage0, g_stage0;
    wire [WIDTH-1:0] p_stage1, g_stage1;
    wire [WIDTH-1:0] p_stage2, g_stage2;
    wire [WIDTH-1:0] p_stage3, g_stage3;
    wire [WIDTH-1:0] carry;
    
    // 用于流水线的寄存器
    reg [WIDTH-1:0] p_stage0_reg, g_stage0_reg;
    reg [WIDTH-1:0] p_stage1_reg, g_stage1_reg;
    reg [WIDTH-1:0] p_stage2_reg, g_stage2_reg;
    reg [WIDTH-1:0] j_reg, k_reg, q_reg;
    
    // 使用Kogge-Stone加法器计算增强后的值
    // 第0阶段: 生成初始P和G
    assign p_stage0 = j ^ k;
    assign g_stage0 = j & (~k);
    
    // 流水线寄存器 - 阶段0到阶段1
    always @(posedge clk) begin
        p_stage0_reg <= p_stage0;
        g_stage0_reg <= g_stage0;
        j_reg <= j;
        k_reg <= k;
        q_reg <= q;
    end
    
    // 第1阶段: 计算P和G的第一级传播
    assign p_stage1[0] = p_stage0_reg[0];
    assign g_stage1[0] = g_stage0_reg[0];
    
    genvar l;
    generate
        for (l = 1; l < WIDTH; l = l + 1) begin : stage1
            assign p_stage1[l] = p_stage0_reg[l] & p_stage0_reg[l-1];
            assign g_stage1[l] = g_stage0_reg[l] | (p_stage0_reg[l] & g_stage0_reg[l-1]);
        end
    endgenerate
    
    // 流水线寄存器 - 阶段1到阶段2
    always @(posedge clk) begin
        p_stage1_reg <= p_stage1;
        g_stage1_reg <= g_stage1;
    end
    
    // 第2阶段: 计算P和G的第二级传播
    assign p_stage2[0] = p_stage1_reg[0];
    assign g_stage2[0] = g_stage1_reg[0];
    assign p_stage2[1] = p_stage1_reg[1];
    assign g_stage2[1] = g_stage1_reg[1];
    
    generate
        for (l = 2; l < WIDTH; l = l + 1) begin : stage2
            assign p_stage2[l] = p_stage1_reg[l] & p_stage1_reg[l-2];
            assign g_stage2[l] = g_stage1_reg[l] | (p_stage1_reg[l] & g_stage1_reg[l-2]);
        end
    endgenerate
    
    // 流水线寄存器 - 阶段2到阶段3
    always @(posedge clk) begin
        p_stage2_reg <= p_stage2;
        g_stage2_reg <= g_stage2;
    end
    
    // 第3阶段: 计算P和G的第三级传播 (如果WIDTH >= 8)
    assign p_stage3[0] = p_stage2_reg[0];
    assign g_stage3[0] = g_stage2_reg[0];
    assign p_stage3[1] = p_stage2_reg[1];
    assign g_stage3[1] = g_stage2_reg[1];
    assign p_stage3[2] = p_stage2_reg[2];
    assign g_stage3[2] = g_stage2_reg[2];
    assign p_stage3[3] = p_stage2_reg[3];
    assign g_stage3[3] = g_stage2_reg[3];
    
    generate
        for (l = 4; l < WIDTH; l = l + 1) begin : stage3
            assign p_stage3[l] = p_stage2_reg[l] & p_stage2_reg[l-4];
            assign g_stage3[l] = g_stage2_reg[l] | (p_stage2_reg[l] & g_stage2_reg[l-4]);
        end
    endgenerate
    
    // 计算进位
    assign carry[0] = g_stage3[0];
    generate
        for (l = 1; l < WIDTH; l = l + 1) begin : carry_gen
            assign carry[l] = g_stage3[l];
        end
    endgenerate
    
    // 计算最终结果
    assign next_q[0] = p_stage0_reg[0] ^ 1'b0;  // 无进位输入
    generate
        for (l = 1; l < WIDTH; l = l + 1) begin : sum_gen
            assign next_q[l] = p_stage0_reg[l] ^ carry[l-1];
        end
    endgenerate
    
    // JK触发器逻辑 - 考虑流水线延迟
    always @(posedge clk) begin
        for (i = 0; i < WIDTH; i = i + 1) begin
            case ({j_reg[i], k_reg[i]})
                2'b00: q[i] <= q_reg[i];
                2'b01: q[i] <= 1'b0;
                2'b10: q[i] <= 1'b1;
                2'b11: q[i] <= ~q_reg[i] ^ next_q[i]; // 使用Kogge-Stone加法器增强的结果
            endcase
        end
    end
endmodule