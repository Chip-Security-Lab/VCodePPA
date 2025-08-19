module default_value_mux #(
    parameter WIDTH = 12,
    parameter DEFAULT_VAL = {WIDTH{1'b1}}
)(
    input [WIDTH-1:0] data_a, data_b, data_c,
    input [1:0] mux_select,
    input use_default,
    output [WIDTH-1:0] mux_result
);
    reg [WIDTH-1:0] selected;
    
    always @(*) begin
        case (mux_select)
            2'b00: selected = data_a;
            2'b01: selected = data_b;
            2'b10: selected = data_c;
            default: selected = DEFAULT_VAL;
        endcase
    end
    
    assign mux_result = use_default ? DEFAULT_VAL : selected;
endmodule