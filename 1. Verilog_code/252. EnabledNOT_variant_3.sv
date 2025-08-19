//SystemVerilog
// 顶层模块
module EnabledNOT #(
    parameter WIDTH = 4
)(
    input                 en,
    input      [WIDTH-1:0] src,
    output     [WIDTH-1:0] result
);
    // 实例化优化后的NOT运算模块
    OptimizedNOT #(
        .WIDTH(WIDTH)
    ) optimized_not_inst (
        .en(en),
        .src(src),
        .result(result)
    );
endmodule

// 优化的NOT运算模块，参数化设计提高可复用性
module OptimizedNOT #(
    parameter WIDTH = 4
)(
    input                  en,
    input      [WIDTH-1:0] src,
    output reg [WIDTH-1:0] result
);
    // 采用单一always块处理所有位，减少资源使用
    always @(*) begin
        if (en)
            result = ~src;
        else
            result = {WIDTH{1'bz}};
    end
endmodule