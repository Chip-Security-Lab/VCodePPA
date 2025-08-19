//SystemVerilog
module RangeDetector_SyncEnRst #(
    parameter WIDTH = 8
)(
    input clk, rst_n, en,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] lower_bound,
    input [WIDTH-1:0] upper_bound,
    output reg out_flag
);
    // 声明用于条件反相减法器的信号
    wire [WIDTH-1:0] diff_lower, diff_upper;
    wire lower_valid, upper_valid;
    
    // 使用条件反相减法器算法实现比较功能
    // 下界检查: data_in >= lower_bound
    conditional_sub #(
        .WIDTH(WIDTH)
    ) lower_check (
        .minuend(data_in),
        .subtrahend(lower_bound),
        .difference(diff_lower),
        .valid(lower_valid)
    );
    
    // 上界检查: data_in <= upper_bound
    conditional_sub #(
        .WIDTH(WIDTH)
    ) upper_check (
        .minuend(upper_bound),
        .subtrahend(data_in),
        .difference(diff_upper),
        .valid(upper_valid)
    );
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) 
            out_flag <= 1'b0;
        else if(en) begin
            out_flag <= lower_valid && upper_valid;
        end
    end
endmodule

module conditional_sub #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] minuend,
    input [WIDTH-1:0] subtrahend,
    output [WIDTH-1:0] difference,
    output valid
);
    wire [WIDTH-1:0] not_subtrahend;
    wire [WIDTH:0] result;
    wire carry;
    
    // 对减数取反
    assign not_subtrahend = ~subtrahend;
    
    // 执行加法: minuend + (~subtrahend) + 1
    assign result = minuend + not_subtrahend + 1'b1;
    
    // 提取进位位
    assign carry = result[WIDTH];
    
    // 结果有效性判断(如果进位为1，表示minuend>=subtrahend)
    assign valid = carry;
    
    // 差值输出
    assign difference = result[WIDTH-1:0];
endmodule