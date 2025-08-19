//SystemVerilog
module clock_divider #(parameter DIVIDE_BY = 2) (
    input wire clk_in, reset,
    output reg clk_out
);
    reg [$clog2(DIVIDE_BY)-1:0] count;
    wire [$clog2(DIVIDE_BY)-1:0] next_count;
    wire [$clog2(DIVIDE_BY)-1:0] count_complement;
    wire [$clog2(DIVIDE_BY)-1:0] half_divisor;
    wire count_reached_limit;
    
    // Calculate two's complement for subtraction as addition
    assign count_complement = ~(DIVIDE_BY/2 - 1) + 1'b1;
    assign half_divisor = DIVIDE_BY/2 - 1;
    
    // 使用比较器代替两个数相加
    assign count_reached_limit = (count == half_divisor);
    
    // 简化next_count逻辑
    assign next_count = count_reached_limit ? '0 : count + 1'b1;
    
    always @(posedge clk_in) begin
        if (reset) begin
            count <= '0;
            clk_out <= 1'b0;
        end else if (count_reached_limit) begin
            clk_out <= ~clk_out;
            count <= '0;
        end else begin
            count <= next_count;
        end
    end
endmodule