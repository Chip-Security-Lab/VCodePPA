//SystemVerilog
module default_value_mux #(
    parameter WIDTH = 12,
    parameter DEFAULT_VAL = {WIDTH{1'b1}}
)(
    input [WIDTH-1:0] data_a, data_b, data_c,
    input [1:0] mux_select,
    input use_default,
    output [WIDTH-1:0] mux_result
);

    // 实例化选择器子模块
    selector #(
        .WIDTH(WIDTH),
        .DEFAULT_VAL(DEFAULT_VAL)
    ) selector_inst (
        .data_a(data_a),
        .data_b(data_b),
        .data_c(data_c),
        .mux_select(mux_select),
        .selected(selected)
    );

    // 实例化默认值控制子模块
    default_control #(
        .WIDTH(WIDTH),
        .DEFAULT_VAL(DEFAULT_VAL)
    ) default_control_inst (
        .selected(selected),
        .use_default(use_default),
        .mux_result(mux_result)
    );

endmodule

// 选择器子模块
module selector #(
    parameter WIDTH = 12,
    parameter DEFAULT_VAL = {WIDTH{1'b1}}
)(
    input [WIDTH-1:0] data_a, data_b, data_c,
    input [1:0] mux_select,
    output reg [WIDTH-1:0] selected
);

    always @(*) begin
        case (mux_select)
            2'b00: selected = data_a;
            2'b01: selected = data_b;
            2'b10: selected = data_c;
            default: selected = DEFAULT_VAL;
        endcase
    end

endmodule

// 默认值控制子模块
module default_control #(
    parameter WIDTH = 12,
    parameter DEFAULT_VAL = {WIDTH{1'b1}}
)(
    input [WIDTH-1:0] selected,
    input use_default,
    output [WIDTH-1:0] mux_result
);

    assign mux_result = use_default ? DEFAULT_VAL : selected;

endmodule