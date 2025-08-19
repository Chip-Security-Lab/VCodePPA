//SystemVerilog
// 顶层模块
module EdgeMatcher #(
    parameter WIDTH = 8
)(
    input                clk,
    input  [WIDTH-1:0]   data_in,
    input  [WIDTH-1:0]   pattern,
    output               edge_match
);
    wire pattern_match;
    wire last_match;
    
    // 模式匹配子模块
    PatternComparator #(
        .WIDTH(WIDTH)
    ) pattern_comp_inst (
        .clk        (clk),
        .data_in    (data_in),
        .pattern    (pattern),
        .match      (pattern_match)
    );
    
    // 边沿检测子模块
    EdgeDetector edge_detect_inst (
        .clk        (clk),
        .match_in   (pattern_match),
        .last_match (last_match),
        .edge_found (edge_match)
    );
    
endmodule

// 模式比较子模块
module PatternComparator #(
    parameter WIDTH = 8
)(
    input                clk,
    input  [WIDTH-1:0]   data_in,
    input  [WIDTH-1:0]   pattern,
    output reg           match
);
    always @(posedge clk) begin
        match <= (data_in == pattern);
    end
endmodule

// 边沿检测子模块
module EdgeDetector (
    input       clk,
    input       match_in,
    output reg  last_match,
    output reg  edge_found
);
    always @(posedge clk) begin
        last_match <= match_in;
        edge_found <= match_in && !last_match;
    end
endmodule