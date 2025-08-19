//SystemVerilog
// Top-level module for Saturating Division
module SatDivTop(
    input [7:0] a, b,
    output [7:0] q
);
    wire [7:0] div_result;
    wire div_zero;

    // Instantiate the division logic
    DivLogic div_inst (
        .a(a),
        .b(b),
        .q(div_result),
        .zero(div_zero)
    );

    // Output logic to handle saturation using explicit multiplexer
    wire [7:0] sat_value = 8'hFF;
    wire [7:0] mux_out;
    
    assign mux_out = div_zero ? sat_value : div_result;
    assign q = mux_out;

endmodule

// Submodule for Division Logic
module DivLogic(
    input [7:0] a, b,
    output [7:0] q,
    output zero
);
    // Division result register
    reg [7:0] div_result;
    
    // Zero detection
    wire is_zero;
    assign is_zero = (b == 8'h00);
    
    // Default value when division by zero
    wire [7:0] default_value = 8'h00;
    
    // Multiplexer for division result
    assign q = is_zero ? default_value : (a / b);
    
    // Zero flag output
    assign zero = is_zero;
endmodule