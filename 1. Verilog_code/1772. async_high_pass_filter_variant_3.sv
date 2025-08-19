//SystemVerilog
module async_high_pass_filter #(
    parameter DATA_WIDTH = 10
)(
    input wire clk,                       // 时钟信号
    input wire rst_n,                     // 复位信号
    input wire [DATA_WIDTH-1:0] signal_input,
    input wire [DATA_WIDTH-1:0] avg_input,      // 移动平均输入
    output reg [DATA_WIDTH-1:0] filtered_out
);
    // 内部信号声明 - 创建流水线寄存器
    reg [DATA_WIDTH-1:0] signal_reg_stage1;
    reg [DATA_WIDTH-1:0] avg_reg_stage1;
    reg [DATA_WIDTH-1:0] diff_result;
    
    // 第一级流水线 - 注册输入信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            signal_reg_stage1 <= {DATA_WIDTH{1'b0}};
            avg_reg_stage1 <= {DATA_WIDTH{1'b0}};
        end else begin
            signal_reg_stage1 <= signal_input;
            avg_reg_stage1 <= avg_input;
        end
    end
    
    // 第二级流水线 - 计算差值
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            diff_result <= {DATA_WIDTH{1'b0}};
        end else begin
            diff_result <= signal_reg_stage1 - avg_reg_stage1;
        end
    end
    
    // 输出级
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            filtered_out <= {DATA_WIDTH{1'b0}};
        end else begin
            filtered_out <= diff_result;
        end
    end
    
endmodule