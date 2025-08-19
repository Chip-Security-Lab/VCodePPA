//SystemVerilog
module sync_rate_limiter #(
    parameter DATA_W = 12,
    parameter MAX_CHANGE = 10
)(
    input clk, rst,
    input [DATA_W-1:0] in_value,
    output reg [DATA_W-1:0] out_value
);
    // 寄存器声明
    reg [DATA_W-1:0] in_value_reg;
    reg [DATA_W-1:0] out_value_feedback;
    wire [DATA_W-1:0] diff;
    wire [DATA_W-1:0] limited_change;
    wire [DATA_W-1:0] next_out_value;
    wire in_greater_than_out;
    
    // 输入寄存和反馈路径
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            in_value_reg <= 0;
            out_value_feedback <= 0;
        end else begin
            in_value_reg <= in_value;
            out_value_feedback <= out_value;
        end
    end
    
    // 组合逻辑部分：计算差值和限制变化量
    assign in_greater_than_out = in_value_reg > out_value_feedback;
    assign diff = in_greater_than_out ? 
                 (in_value_reg - out_value_feedback) : 
                 (out_value_feedback - in_value_reg);
    assign limited_change = (diff > MAX_CHANGE) ? MAX_CHANGE : diff;
    
    // 组合逻辑：计算下一个输出值
    assign next_out_value = (in_value_reg == out_value_feedback) ? out_value_feedback :
                           (in_greater_than_out) ? out_value_feedback + limited_change :
                           out_value_feedback - limited_change;
    
    // 输出寄存器
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out_value <= 0;
        end else begin
            out_value <= next_out_value;
        end
    end
endmodule