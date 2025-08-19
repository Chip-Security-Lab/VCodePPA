//SystemVerilog
module ITRC_DigitalFilter #(
    parameter WIDTH = 8,
    parameter FILTER_CYCLES = 3
)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] noisy_int,
    output reg [WIDTH-1:0] filtered_int
);
    reg [WIDTH-1:0] shift_reg [0:FILTER_CYCLES-1];
    integer i;
    genvar j;
    
    // 流水线寄存器
    reg [WIDTH-1:0] p_stage1 [0:FILTER_CYCLES-1];
    reg [WIDTH-1:0] g_stage1 [0:FILTER_CYCLES-1];
    reg [WIDTH-1:0] p_stage2;
    reg [WIDTH-1:0] g_stage2;
    reg [WIDTH-1:0] sum_stage1;
    
    // 并行前缀加法器相关信号
    wire [WIDTH-1:0] sum;
    wire [WIDTH:0] carry;
    wire [WIDTH-1:0] p [0:FILTER_CYCLES-1];
    wire [WIDTH-1:0] g [0:FILTER_CYCLES-1];
    
    always @(posedge clk) begin
        if (!rst_n) begin
            for (i=0; i<FILTER_CYCLES; i=i+1)
                shift_reg[i] <= 0;
        end else begin
            shift_reg[0] <= noisy_int;
            for (i=1; i<FILTER_CYCLES; i=i+1)
                shift_reg[i] <= shift_reg[i-1];
        end
    end
    
    // 第一阶段：生成传播和生成信号
    generate
        for (j=0; j<WIDTH; j=j+1) begin : prefix_gen
            assign p[0][j] = shift_reg[0][j] ^ shift_reg[1][j];
            assign g[0][j] = shift_reg[0][j] & shift_reg[1][j];
        end
    endgenerate
    
    // 第一阶段流水线寄存器
    always @(posedge clk) begin
        if (!rst_n) begin
            for (i=0; i<FILTER_CYCLES; i=i+1) begin
                p_stage1[i] <= 0;
                g_stage1[i] <= 0;
            end
        end else begin
            p_stage1[0] <= p[0];
            g_stage1[0] <= g[0];
        end
    end
    
    // 第二阶段：计算中间结果
    generate
        for (j=0; j<WIDTH; j=j+1) begin : prefix_stage2
            assign p[1][j] = p_stage1[0][j] & shift_reg[2][j];
            assign g[1][j] = (p_stage1[0][j] & shift_reg[2][j]) | g_stage1[0][j];
        end
    endgenerate
    
    // 第二阶段流水线寄存器
    always @(posedge clk) begin
        if (!rst_n) begin
            p_stage2 <= 0;
            g_stage2 <= 0;
        end else begin
            p_stage2 <= p[1];
            g_stage2 <= g[1];
        end
    end
    
    // 第三阶段：计算最终和
    generate
        for (j=0; j<WIDTH; j=j+1) begin : final_sum
            assign sum[j] = p_stage2[j] ^ g_stage2[j];
        end
    endgenerate
    
    // 更新输出
    always @(posedge clk) begin
        if (!rst_n)
            filtered_int <= 0;
        else
            filtered_int <= sum;
    end
endmodule