//SystemVerilog
module sync_rate_limiter #(
    parameter DATA_W = 12,
    parameter MAX_CHANGE = 10
)(
    input clk, rst,
    input [DATA_W-1:0] in_value,
    output reg [DATA_W-1:0] out_value
);
    // 输入值缓冲信号，用于减少扇出
    reg [DATA_W-1:0] in_value_buf1, in_value_buf2;
    // 输出值缓冲信号，用于减少扇出
    reg [DATA_W-1:0] out_value_buf1, out_value_buf2;
    
    // 差值信号
    wire [DATA_W-1:0] diff;
    reg [DATA_W-1:0] diff_buf;
    
    // 限制变化量信号
    wire [DATA_W-1:0] limited_change;
    reg [DATA_W-1:0] limited_change_buf;
    
    // 输入输出方向指示信号，1:增加，0:减少
    reg direction;
    
    // 输入值缓冲逻辑
    always @(posedge clk) begin
        in_value_buf1 <= in_value;
        in_value_buf2 <= in_value;
    end
    
    // 输出值缓冲逻辑
    always @(posedge clk) begin
        out_value_buf1 <= out_value;
        out_value_buf2 <= out_value;
    end
    
    // 差值计算逻辑
    assign diff = (in_value_buf1 > out_value_buf1) ? 
                 (in_value_buf1 - out_value_buf1) : (out_value_buf1 - in_value_buf1);
    
    // 方向判断逻辑
    always @(posedge clk) begin
        direction <= (in_value_buf1 > out_value_buf1);
    end
    
    // 差值缓冲逻辑
    always @(posedge clk) begin
        diff_buf <= diff;
    end
    
    // 变化量限制逻辑
    assign limited_change = (diff_buf > MAX_CHANGE) ? MAX_CHANGE : diff_buf;
    
    // 变化量缓冲逻辑
    always @(posedge clk) begin
        limited_change_buf <= limited_change;
    end
    
    // 输出值更新逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out_value <= 0;
        end else if (in_value_buf2 != out_value_buf2) begin
            out_value <= direction ? (out_value_buf2 + limited_change_buf) : 
                                    (out_value_buf2 - limited_change_buf);
        end
    end
endmodule