//SystemVerilog
module TriStateMatcher #(
    parameter WIDTH = 8
)(
    input  logic             clk,      // 添加时钟信号用于流水线
    input  logic             rst_n,    // 添加复位信号
    input  logic [WIDTH-1:0] data,     // 输入数据
    input  logic [WIDTH-1:0] pattern,  // 匹配模式
    input  logic [WIDTH-1:0] mask,     // 掩码: 0=无关位
    output logic             match     // 匹配结果
);
    // 第一级流水线寄存器: 保存输入信号
    logic [WIDTH-1:0] data_reg1, pattern_reg1, mask_reg1;
    
    // 第二级流水线信号
    logic [WIDTH-1:0] masked_data_reg;
    logic [WIDTH-1:0] masked_pattern_reg;
    
    // 第三级流水线信号
    logic [WIDTH-1:0] comparison_result;
    
    // 流水线第一级: 寄存输入信号
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            data_reg1    <= '0;
            pattern_reg1 <= '0;
            mask_reg1    <= '0;
        end else begin
            data_reg1    <= data;
            pattern_reg1 <= pattern;
            mask_reg1    <= mask;
        end
    end

    // 流水线第二级: 生成掩码数据
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            masked_data_reg    <= '0;
            masked_pattern_reg <= '0;
        end else begin
            masked_data_reg    <= data_reg1 & mask_reg1;
            masked_pattern_reg <= pattern_reg1 & mask_reg1;
        end
    end

    // 流水线第三级: 数据比较
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            comparison_result <= '0;
        end else begin
            comparison_result <= masked_data_reg ^ masked_pattern_reg;
        end
    end

    // 流水线第四级: 归约和输出
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            match <= 1'b0;
        end else begin
            match <= ~|comparison_result;
        end
    end
endmodule