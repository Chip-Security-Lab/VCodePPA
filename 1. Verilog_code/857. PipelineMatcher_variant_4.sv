//SystemVerilog
// 顶层模块
module PipelineMatcher #(
    parameter WIDTH = 8
)(
    input  wire clk,
    input  wire [WIDTH-1:0] data_in,
    input  wire [WIDTH-1:0] pattern,
    output wire match
);
    // 内部连接信号
    wire [WIDTH-1:0] registered_data;
    
    // 实例化数据寄存子模块
    DataRegister #(
        .WIDTH(WIDTH)
    ) data_reg_inst (
        .clk      (clk),
        .data_in  (data_in),
        .data_out (registered_data)
    );
    
    // 实例化比较器子模块
    PatternComparator #(
        .WIDTH(WIDTH)
    ) comparator_inst (
        .clk       (clk),
        .data      (registered_data),
        .pattern   (pattern),
        .match_out (match)
    );
    
endmodule

// 数据寄存子模块
module DataRegister #(
    parameter WIDTH = 8
)(
    input  wire clk,
    input  wire [WIDTH-1:0] data_in,
    output reg  [WIDTH-1:0] data_out
);
    always @(posedge clk) begin
        data_out <= data_in;
    end
endmodule

// 优化后的比较器子模块
module PatternComparator #(
    parameter WIDTH = 8
)(
    input  wire clk,
    input  wire [WIDTH-1:0] data,
    input  wire [WIDTH-1:0] pattern,
    output reg  match_out
);
    // 预计算匹配结果以减少关键路径
    reg pattern_match;
    
    always @(posedge clk) begin
        // 合并操作：先计算匹配结果，再赋值给输出
        pattern_match <= (data == pattern);
        match_out <= pattern_match;
    end
endmodule