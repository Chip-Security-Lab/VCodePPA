//SystemVerilog
module shift_pattern_matcher #(parameter WIDTH = 8) (
    input clk, rst_n, data_in,
    input [WIDTH-1:0] pattern,
    output reg match_out
);
    reg [WIDTH-1:0] shift_reg;
    wire [WIDTH-1:0] shift_reg_next;
    wire match_next;
    
    // 移位寄存器逻辑保持不变
    assign shift_reg_next = {shift_reg[WIDTH-2:0], data_in};
    
    // 使用条件求和减法算法实现比较逻辑
    wire [WIDTH:0] difference;
    wire [WIDTH-1:0] inverted_pattern;
    wire carry_in;
    
    assign inverted_pattern = ~pattern;
    assign carry_in = 1'b1;  // 补码表示法的-1操作
    
    // 条件求和减法: shift_reg_next - pattern
    // 使用补码: shift_reg_next + (~pattern + 1)
    assign difference = {1'b0, shift_reg_next} + {1'b0, inverted_pattern} + carry_in;
    
    // 如果差值为0，则匹配
    assign match_next = (difference[WIDTH-1:0] == {WIDTH{1'b0}});
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= {WIDTH{1'b0}};
            match_out <= 1'b0;
        end else begin
            shift_reg <= shift_reg_next;
            match_out <= match_next;
        end
    end
endmodule