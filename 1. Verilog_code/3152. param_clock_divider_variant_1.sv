//SystemVerilog
module param_clock_divider #(
    parameter DIVISOR = 10
)(
    input wire clock_i,
    input wire reset_i,
    output reg clock_o
);
    // 优化位宽计算，确保精确匹配所需位数
    localparam COUNT_WIDTH = $clog2(DIVISOR);
    reg [COUNT_WIDTH-1:0] count;
    
    // 预计算比较值
    localparam [COUNT_WIDTH-1:0] COMPARE_VALUE = DIVISOR - 1;
    
    // 条件求和减法实现计数逻辑
    wire [COUNT_WIDTH-1:0] next_count;
    wire borrow;
    
    // 检测是否到达最大值
    assign {borrow, next_count} = count_max ? {1'b0, {COUNT_WIDTH{1'b0}}} : {1'b0, count} + {1'b0, 1'b1};
    
    // 使用更高效的比较逻辑
    wire count_max = (count == COMPARE_VALUE);
    
    always @(posedge clock_i) begin
        if (reset_i) begin
            count <= 0;
            clock_o <= 0;
        end else begin
            count <= next_count;
            if (count_max) begin
                clock_o <= ~clock_o;
            end
        end
    end
endmodule