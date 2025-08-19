//SystemVerilog
module TimeoutMatcher #(parameter WIDTH=8, TIMEOUT=100) (
    input clk, rst_n,
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] pattern,
    output timeout
);

wire match;

// Pattern Comparator Module
PatternComparator #(.WIDTH(WIDTH)) pattern_cmp (
    .data(data),
    .pattern(pattern),
    .match(match)
);

// Timeout Counter Module
TimeoutCounter #(.TIMEOUT(TIMEOUT)) timeout_cnt (
    .clk(clk),
    .rst_n(rst_n),
    .match(match),
    .timeout(timeout)
);

endmodule

module PatternComparator #(parameter WIDTH=8) (
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] pattern,
    output match
);

// 优化: 直接使用逻辑表达式，消除always块和reg信号
assign match = (data == pattern);

endmodule

module TimeoutCounter #(parameter TIMEOUT=100) (
    input clk, rst_n,
    input match,
    output reg timeout
);

reg [15:0] counter;
reg next_timeout;
reg [15:0] next_counter;

// 优化: 拆分组合逻辑和时序逻辑，减少关键路径
always @(*) begin
    // 优化逻辑路径，先计算下一个计数值
    if (match)
        next_counter = 0;
    else
        next_counter = counter + 1;
    
    // 预先计算timeout信号
    next_timeout = (next_counter >= TIMEOUT);
end

// 时序逻辑更新
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        counter <= 0;
        timeout <= 0;
    end else begin
        counter <= next_counter;
        timeout <= next_timeout;
    end
end

endmodule