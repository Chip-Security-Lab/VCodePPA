//SystemVerilog
/*
 * 模块名: xor2_7
 * 功能: 位宽可配置的异或运算单元，具有流水线结构
 * 设计: 组合逻辑和时序逻辑分离设计
 */
module xor2_7 #(
    parameter WIDTH = 8
)(
    input  wire               clk,       // 系统时钟
    input  wire               rst_n,     // 异步复位，低有效
    input  wire [WIDTH-1:0]   A_in,      // 输入操作数A
    input  wire [WIDTH-1:0]   B_in,      // 输入操作数B
    input  wire               data_vld,  // 输入数据有效标志
    output wire [WIDTH-1:0]   Y_out,     // 异或结果输出
    output wire               result_vld // 输出结果有效标志
);

    // 内部信号定义 - 寄存器信号
    reg [WIDTH-1:0] A_reg, B_reg;       // 输入数据寄存器
    reg [WIDTH-1:0] xor_stage1_reg;     // 第一级异或结果寄存器
    reg [WIDTH-1:0] xor_stage2_reg;     // 第二级异或结果寄存器(输出)
    reg data_vld_r1, data_vld_r2;       // 有效标志流水线寄存器

    // 组合逻辑信号
    wire [WIDTH-1:0] xor_stage1_comb;   // 组合逻辑异或结果

    // 组合逻辑部分 - 异或计算
    assign xor_stage1_comb = A_reg ^ B_reg;

    // 时序逻辑部分 - 输入寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            A_reg <= {WIDTH{1'b0}};
            B_reg <= {WIDTH{1'b0}};
            data_vld_r1 <= 1'b0;
        end else begin
            A_reg <= A_in;
            B_reg <= B_in;
            data_vld_r1 <= data_vld;
        end
    end

    // 时序逻辑部分 - 计算阶段1寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            xor_stage1_reg <= {WIDTH{1'b0}};
            data_vld_r2 <= 1'b0;
        end else begin
            xor_stage1_reg <= xor_stage1_comb;
            data_vld_r2 <= data_vld_r1;
        end
    end

    // 时序逻辑部分 - 输出寄存器阶段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            xor_stage2_reg <= {WIDTH{1'b0}};
        end else begin
            xor_stage2_reg <= xor_stage1_reg;
        end
    end

    // 组合逻辑部分 - 输出端口赋值
    assign Y_out = xor_stage2_reg;
    assign result_vld = data_vld_r2;

endmodule