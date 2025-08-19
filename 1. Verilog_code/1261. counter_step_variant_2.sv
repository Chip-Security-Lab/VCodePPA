//SystemVerilog
module counter_step #(parameter WIDTH=4, STEP=2) (
    input  wire               clk,
    input  wire               rst_n,
    output reg  [WIDTH-1:0]   cnt
);
    // 内部信号声明
    wire [WIDTH-1:0] next_cnt;
    
    // 实例化流水线前缀加法器
    pipelined_prefix_adder #(.WIDTH(WIDTH)) adder (
        .clk        (clk),
        .rst_n      (rst_n),
        .a          (cnt),
        .b          (STEP),
        .sum        (next_cnt)
    );
    
    // 状态更新逻辑
    always @(posedge clk) begin
        if (!rst_n)
            cnt <= {WIDTH{1'b0}};
        else
            cnt <= next_cnt;
    end
endmodule

module pipelined_prefix_adder #(parameter WIDTH=8) (
    input  wire               clk,
    input  wire               rst_n,
    input  wire [WIDTH-1:0]   a,
    input  wire [WIDTH-1:0]   b,
    output wire [WIDTH-1:0]   sum
);
    // 流水线阶段1: 初始生成和传播信号
    reg  [WIDTH-1:0] a_stage1, b_stage1;
    wire [WIDTH-1:0] g_init, p_init;
    reg  [WIDTH-1:0] g_stage1, p_stage1;
    
    // 阶段1寄存器
    always @(posedge clk) begin
        if (!rst_n) begin
            a_stage1 <= {WIDTH{1'b0}};
            b_stage1 <= {WIDTH{1'b0}};
            g_stage1 <= {WIDTH{1'b0}};
            p_stage1 <= {WIDTH{1'b0}};
        end
        else begin
            a_stage1 <= a;
            b_stage1 <= b;
            g_stage1 <= g_init;
            p_stage1 <= p_init;
        end
    end
    
    // 第一阶段：计算初始生成和传播信号
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_init
            assign g_init[i] = a[i] & b[i];
            assign p_init[i] = a[i] | b[i];
        end
    endgenerate
    
    // 流水线阶段2: 前缀树计算
    wire [WIDTH-1:0] g_final, p_final;
    reg  [WIDTH-1:0] g_stage2, p_stage2;
    reg  [WIDTH-1:0] a_stage2, b_stage2;
    
    // 阶段2寄存器
    always @(posedge clk) begin
        if (!rst_n) begin
            g_stage2 <= {WIDTH{1'b0}};
            p_stage2 <= {WIDTH{1'b0}};
            a_stage2 <= {WIDTH{1'b0}};
            b_stage2 <= {WIDTH{1'b0}};
        end
        else begin
            g_stage2 <= g_final;
            p_stage2 <= p_final;
            a_stage2 <= a_stage1;
            b_stage2 <= b_stage1;
        end
    end
    
    // 前缀树计算模块
    optimized_prefix_tree #(.WIDTH(WIDTH)) tree (
        .g_in       (g_stage1),
        .p_in       (p_stage1),
        .g_out      (g_final),
        .p_out      (p_final)
    );
    
    // 流水线阶段3: 计算最终和
    wire [WIDTH:0] carry;
    wire [WIDTH-1:0] sum_internal;
    
    assign carry[0] = 1'b0;
    
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_sum
            assign carry[i+1] = g_stage2[i] | (p_stage2[i] & carry[i]);
            assign sum_internal[i] = a_stage2[i] ^ b_stage2[i] ^ carry[i];
        end
    endgenerate
    
    // 输出寄存器
    reg [WIDTH-1:0] sum_reg;
    
    always @(posedge clk) begin
        if (!rst_n)
            sum_reg <= {WIDTH{1'b0}};
        else
            sum_reg <= sum_internal;
    end
    
    assign sum = sum_reg;
endmodule

module optimized_prefix_tree #(parameter WIDTH=8) (
    input  wire [WIDTH-1:0] g_in,
    input  wire [WIDTH-1:0] p_in,
    output wire [WIDTH-1:0] g_out,
    output wire [WIDTH-1:0] p_out
);
    // 级间信号 - 用于分段优化的Kogge-Stone并行前缀结构
    wire [WIDTH-1:0] g_stage [0:3]; // log2(WIDTH)级
    wire [WIDTH-1:0] p_stage [0:3];
    
    // 初始阶段输入
    assign g_stage[0] = g_in;
    assign p_stage[0] = p_in;
    
    // 第一级前缀计算 (距离1) - 优化的Kogge-Stone结构
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : stage1
            if (i == 0) begin
                // 第一位保持不变
                assign g_stage[1][i] = g_stage[0][i];
                assign p_stage[1][i] = p_stage[0][i];
            end else begin
                // 前缀组合计算
                assign g_stage[1][i] = g_stage[0][i] | (p_stage[0][i] & g_stage[0][i-1]);
                assign p_stage[1][i] = p_stage[0][i] & p_stage[0][i-1];
            end
        end
    endgenerate
    
    // 第二级前缀计算 (距离2) - 减少逻辑深度
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : stage2
            if (i < 2) begin
                // 前两位保持不变
                assign g_stage[2][i] = g_stage[1][i];
                assign p_stage[2][i] = p_stage[1][i];
            end else begin
                // 优化的前缀组合计算
                assign g_stage[2][i] = g_stage[1][i] | (p_stage[1][i] & g_stage[1][i-2]);
                assign p_stage[2][i] = p_stage[1][i] & p_stage[1][i-2];
            end
        end
    endgenerate
    
    // 第三级前缀计算 (距离4) - 平衡资源与延迟
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : stage3
            if (i < 4) begin
                // 前四位保持不变
                assign g_stage[3][i] = g_stage[2][i];
                assign p_stage[3][i] = p_stage[2][i];
            end else begin
                // 最终组合计算
                assign g_stage[3][i] = g_stage[2][i] | (p_stage[2][i] & g_stage[2][i-4]);
                assign p_stage[3][i] = p_stage[2][i] & p_stage[2][i-4];
            end
        end
    endgenerate
    
    // 输出赋值
    assign g_out = g_stage[3];
    assign p_out = p_stage[3];
endmodule