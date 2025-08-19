//SystemVerilog
// 比较器核心逻辑子模块
module Comparator_Core #(
    parameter WIDTH = 32
)(
    input  [WIDTH-1:0]  a,
    input  [WIDTH-1:0]  b,
    output             equal,
    output             greater,
    output             less
);
    assign equal   = (a == b);
    assign greater = (a > b);
    assign less    = (a < b);
endmodule

// 比较结果选择子模块
module Comparator_Selector #(
    parameter TYPE = 0
)(
    input        enable,
    input        equal,
    input        greater,
    input        less,
    output reg   res
);
    always @(*) begin
        if (enable) begin
            if (TYPE == 0) begin
                res = equal;
            end else if (TYPE == 1) begin
                res = greater;
            end else begin
                res = less;
            end
        end else begin
            res = 1'b0;
        end
    end
endmodule

// 顶层比较器模块
module Comparator_MultiMode #(
    parameter TYPE = 0,
    parameter WIDTH = 32
)(
    input               enable,
    input  [WIDTH-1:0]  a,
    input  [WIDTH-1:0]  b,
    output              res
);
    wire equal, greater, less;

    Comparator_Core #(
        .WIDTH(WIDTH)
    ) core_inst (
        .a(a),
        .b(b),
        .equal(equal),
        .greater(greater),
        .less(less)
    );

    Comparator_Selector #(
        .TYPE(TYPE)
    ) selector_inst (
        .enable(enable),
        .equal(equal),
        .greater(greater),
        .less(less),
        .res(res)
    );
endmodule