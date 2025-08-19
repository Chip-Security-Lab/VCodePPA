module ternary_mux (
    input wire [1:0] selector,    // Selection control
    input wire [7:0] input_a, input_b, input_c, input_d, // Inputs
    output wire [7:0] mux_out     // Output result
);
    assign mux_out = (selector == 2'b00) ? input_a :
                     (selector == 2'b01) ? input_b :
                     (selector == 2'b10) ? input_c : input_d;
endmodule