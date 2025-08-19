//SystemVerilog
// 顶层模块
module DoubleBufferMatcher #(
    parameter WIDTH = 8
) (
    input clk,
    input sel_buf,
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] pattern0, pattern1,
    output match
);
    // 内部连线
    wire [WIDTH-1:0] selected_pattern;
    
    // 实例化子模块
    PatternSelector #(
        .WIDTH(WIDTH)
    ) pattern_selector_inst (
        .sel_buf(sel_buf),
        .pattern0(pattern0),
        .pattern1(pattern1),
        .selected_pattern(selected_pattern)
    );
    
    ComparatorUnit #(
        .WIDTH(WIDTH)
    ) comparator_inst (
        .clk(clk),
        .data(data),
        .pattern(selected_pattern),
        .match(match)
    );
    
endmodule

// 子模块1：模式选择器
module PatternSelector #(
    parameter WIDTH = 8
) (
    input sel_buf,
    input [WIDTH-1:0] pattern0, pattern1,
    output reg [WIDTH-1:0] selected_pattern
);
    // 根据选择信号选择对应的模式
    always @(*) begin
        selected_pattern = sel_buf ? pattern1 : pattern0;
    end
endmodule

// 子模块2：比较单元 - 使用先行借位减法器算法
module ComparatorUnit #(
    parameter WIDTH = 8
) (
    input clk,
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] pattern,
    output reg match
);
    wire [WIDTH-1:0] diff;
    wire [WIDTH:0] borrow;
    
    // 生成借位信号
    assign borrow[0] = 1'b0;
    
    generate
        genvar i;
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_borrow
            assign borrow[i+1] = (~data[i] & pattern[i]) | 
                                 (~data[i] & borrow[i]) |
                                 (borrow[i] & pattern[i]);
        end
    endgenerate
    
    // 计算差值
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_diff
            assign diff[i] = data[i] ^ pattern[i] ^ borrow[i];
        end
    endgenerate
    
    // 检查是否匹配（差值为零）
    reg is_zero;
    
    always @(*) begin
        is_zero = 1'b1;
        for (int j = 0; j < WIDTH; j = j + 1) begin
            if (diff[j] != 1'b0)
                is_zero = 1'b0;
        end
    end
    
    // 时序比较逻辑
    always @(posedge clk) begin
        match <= is_zero;
    end
endmodule