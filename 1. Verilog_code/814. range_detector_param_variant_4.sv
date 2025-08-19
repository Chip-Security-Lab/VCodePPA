//SystemVerilog
module range_detector_param #(
    parameter DATA_WIDTH = 32
)(
    input wire clk,                    // 添加时钟信号用于流水线
    input wire rst_n,                  // 添加复位信号
    input wire [DATA_WIDTH-1:0] data,
    input wire [DATA_WIDTH-1:0] lower, upper,
    output wire in_bounds
);
    // 内部流水线信号
    reg [DATA_WIDTH-1:0] data_reg, lower_reg, upper_reg;
    wire lower_check, upper_check;
    reg lower_check_reg, upper_check_reg;
    
    // 第一级流水线：寄存输入数据
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= {DATA_WIDTH{1'b0}};
            lower_reg <= {DATA_WIDTH{1'b0}};
            upper_reg <= {DATA_WIDTH{1'b0}};
        end else begin
            data_reg <= data;
            lower_reg <= lower;
            upper_reg <= upper;
        end
    end
    
    // 第二级流水线：并行比较操作
    assign lower_check = (data_reg >= lower_reg);
    assign upper_check = (data_reg <= upper_reg);
    
    // 第三级流水线：寄存比较结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lower_check_reg <= 1'b0;
            upper_check_reg <= 1'b0;
        end else begin
            lower_check_reg <= lower_check;
            upper_check_reg <= upper_check;
        end
    end
    
    // 最终结果合并
    assign in_bounds = lower_check_reg && upper_check_reg;
    
endmodule