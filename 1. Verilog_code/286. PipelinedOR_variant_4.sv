//SystemVerilog
module PipelinedOR(
    input clk,
    input [15:0] stage_a, stage_b,
    output reg [15:0] out
);
    // 分割数据路径，添加中间寄存器
    reg [7:0] stage_a_upper_reg, stage_a_lower_reg;
    reg [7:0] stage_b_upper_reg, stage_b_lower_reg;
    reg [7:0] result_upper, result_lower;
    
    // 第一流水级：高8位数据寄存
    always @(posedge clk) begin
        stage_a_upper_reg <= stage_a[15:8];
        stage_b_upper_reg <= stage_b[15:8];
    end
    
    // 第一流水级：低8位数据寄存
    always @(posedge clk) begin
        stage_a_lower_reg <= stage_a[7:0];
        stage_b_lower_reg <= stage_b[7:0];
    end
    
    // 第二流水级：高8位OR运算
    always @(posedge clk) begin
        result_upper <= stage_a_upper_reg | stage_b_upper_reg;
    end
    
    // 第二流水级：低8位OR运算
    always @(posedge clk) begin
        result_lower <= stage_a_lower_reg | stage_b_lower_reg;
    end
    
    // 第三流水级：合并结果
    always @(posedge clk) begin
        out <= {result_upper, result_lower};
    end
endmodule