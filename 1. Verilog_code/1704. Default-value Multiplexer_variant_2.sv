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

    wire [WIDTH-1:0] mux_output;
    
    data_selector #(
        .WIDTH(WIDTH),
        .DEFAULT_VAL(DEFAULT_VAL)
    ) selector (
        .data_a(data_a),
        .data_b(data_b),
        .data_c(data_c),
        .mux_select(mux_select),
        .selected_data(mux_output)
    );
    
    default_value_control #(
        .WIDTH(WIDTH),
        .DEFAULT_VAL(DEFAULT_VAL)
    ) control (
        .selected_data(mux_output),
        .use_default(use_default),
        .mux_result(mux_result)
    );

endmodule

module data_selector #(
    parameter WIDTH = 12,
    parameter DEFAULT_VAL = {WIDTH{1'b1}}
)(
    input [WIDTH-1:0] data_a, data_b, data_c,
    input [1:0] mux_select,
    output reg [WIDTH-1:0] selected_data
);

    reg [WIDTH-1:0] data_a_reg;
    reg [WIDTH-1:0] data_b_reg;
    reg [WIDTH-1:0] data_c_reg;
    reg [WIDTH-1:0] default_reg;

    always @(*) begin
        data_a_reg = data_a;
        data_b_reg = data_b;
        data_c_reg = data_c;
        default_reg = DEFAULT_VAL;
    end

    always @(*) begin
        case (mux_select)
            2'b00: selected_data = data_a_reg;
            2'b01: selected_data = data_b_reg;
            2'b10: selected_data = data_c_reg;
            default: selected_data = default_reg;
        endcase
    end

endmodule

module default_value_control #(
    parameter WIDTH = 12,
    parameter DEFAULT_VAL = {WIDTH{1'b1}}
)(
    input [WIDTH-1:0] selected_data,
    input use_default,
    output [WIDTH-1:0] mux_result
);

    reg [WIDTH-1:0] selected_data_reg;
    reg [WIDTH-1:0] default_val_reg;

    always @(*) begin
        selected_data_reg = selected_data;
        default_val_reg = DEFAULT_VAL;
    end

    assign mux_result = use_default ? default_val_reg : selected_data_reg;

endmodule