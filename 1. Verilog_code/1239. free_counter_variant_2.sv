//SystemVerilog
module free_counter #(parameter MAX = 255) (
    input wire clk,
    input wire rst_n,
    output reg [7:0] count,
    output reg tc
);
    // 流水线控制信号
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // 流水线寄存器
    reg [7:0] count_stage1, count_stage2;
    reg tc_stage1, tc_stage2;
    
    // 带状进位加法器分割为两部分
    // 第一部分：生成和传播信号
    wire [7:0] p;
    wire [7:0] g;
    reg [7:0] p_stage1;
    reg [7:0] g_stage1;
    
    // 初始生成和传播信号
    assign p = count;
    assign g = 8'b0; // 对于+1运算，生成位都为0
    
    // 第一级流水线：寄存生成传播信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            p_stage1 <= 8'b0;
            g_stage1 <= 8'b0;
            valid_stage1 <= 1'b0;
        end else begin
            p_stage1 <= p;
            g_stage1 <= g;
            valid_stage1 <= 1'b1;
        end
    end
    
    // 第二部分：计算进位和结果
    wire [8:0] c;
    wire [7:0] count_next;
    wire is_max;
    
    // 低4位进位计算
    assign c[0] = 1'b1; // 加1操作的初始进位
    assign c[1] = g_stage1[0] | (p_stage1[0] & c[0]);
    assign c[2] = g_stage1[1] | (p_stage1[1] & c[1]);
    assign c[3] = g_stage1[2] | (p_stage1[2] & c[2]);
    assign c[4] = g_stage1[3] | (p_stage1[3] & c[3]);
    
    // 高4位进位计算和结果
    assign c[5] = g_stage1[4] | (p_stage1[4] & c[4]);
    assign c[6] = g_stage1[5] | (p_stage1[5] & c[5]);
    assign c[7] = g_stage1[6] | (p_stage1[6] & c[6]);
    assign c[8] = g_stage1[7] | (p_stage1[7] & c[7]);
    
    // 计算下一个计数值和终端计数信号
    assign count_next = p_stage1 ^ c[7:0];
    assign is_max = (count == MAX);
    
    // 第二级流水线：计算结果和比较
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_stage1 <= 8'd0;
            tc_stage1 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else if (valid_stage1) begin
            count_stage1 <= is_max ? 8'd0 : count_next;
            tc_stage1 <= (count == MAX - 1);
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 第三级流水线：增加一级延迟，减轻时序压力
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_stage2 <= 8'd0;
            tc_stage2 <= 1'b0;
            valid_stage3 <= 1'b0;
        end else if (valid_stage2) begin
            count_stage2 <= count_stage1;
            tc_stage2 <= tc_stage1;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // 输出级
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 8'd0;
            tc <= 1'b0;
        end else if (valid_stage3) begin
            count <= count_stage2;
            tc <= tc_stage2;
        end
    end
endmodule