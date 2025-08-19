//SystemVerilog
module range_detector_param #(
    parameter DATA_WIDTH = 32
)(
    input wire clk,                       // 时钟信号
    input wire rst_n,                     // 复位信号
    input wire [DATA_WIDTH-1:0] data,
    input wire [DATA_WIDTH-1:0] lower, upper,
    output wire in_bounds
);
    // 内部信号声明
    reg [DATA_WIDTH-1:0] data_reg, lower_reg, upper_reg;
    reg cmp_lower_result_reg, cmp_upper_result_reg;
    
    // 合并为单一always块处理所有时序逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= {DATA_WIDTH{1'b0}};
            lower_reg <= {DATA_WIDTH{1'b0}};
            upper_reg <= {DATA_WIDTH{1'b0}};
            cmp_lower_result_reg <= 1'b0;
            cmp_upper_result_reg <= 1'b0;
        end else begin
            // 第一级流水线：寄存输入数据
            data_reg <= data;
            lower_reg <= lower;
            upper_reg <= upper;
            
            // 第二级和第三级流水线：直接计算并寄存比较结果
            cmp_lower_result_reg <= (data_reg >= lower_reg);
            cmp_upper_result_reg <= (data_reg <= upper_reg);
        end
    end
    
    // 第四级流水线：组合结果判断
    assign in_bounds = cmp_lower_result_reg && cmp_upper_result_reg;
endmodule