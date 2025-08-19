//SystemVerilog
// Top level module
module Hier_NAND #(
    parameter WIDTH = 2
)(
    input [WIDTH-1:0] a, b,
    output [WIDTH*2-1:0] y
);
    // Instance of subtractor operation unit (replaces NAND)
    Subtractor_LUT_operation #(.WIDTH(WIDTH)) sub_unit (
        .a(a),
        .b(b),
        .y(y[WIDTH-1:0])
    );
    
    // Instance of constant output unit (unchanged)
    Constant_output #(.WIDTH(WIDTH), .VALUE(2'b11)) const_unit (
        .y(y[WIDTH*2-1:WIDTH])
    );
endmodule

// Subtractor operation module using LUT approach
module Subtractor_LUT_operation #(
    parameter WIDTH = 2
)(
    input [WIDTH-1:0] a, b,
    output [WIDTH-1:0] y
);
    // Internal borrow signals between bit stages
    wire [WIDTH-1:0] borrow;
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : sub_gen
            Subtractor_LUT_bit sub_bit (
                .a(a[i]),
                .b(b[i]),
                .borrow_in(i == 0 ? 1'b0 : borrow[i-1]),
                .result(y[i]),
                .borrow_out(borrow[i])
            );
        end
    endgenerate
endmodule

// Single-bit subtractor with lookup table
module Subtractor_LUT_bit(
    input a, b, borrow_in,
    output result, borrow_out
);
    // Intermediate signals for clarity
    reg result_r, borrow_out_r;
    
    // LUT for result computation based on inputs
    always @(*) begin : result_lut
        case({a, b, borrow_in})
            3'b000: result_r = 1'b0; // 0-0-0=0
            3'b001: result_r = 1'b1; // 0-0-1=-1 (1 in 2's complement)
            3'b010: result_r = 1'b1; // 0-1-0=-1 (1 in 2's complement)
            3'b011: result_r = 1'b0; // 0-1-1=-2 (0 in 2's complement with borrow)
            3'b100: result_r = 1'b1; // 1-0-0=1
            3'b101: result_r = 1'b0; // 1-0-1=0
            3'b110: result_r = 1'b0; // 1-1-0=0
            3'b111: result_r = 1'b1; // 1-1-1=-1 (1 in 2's complement)
            default: result_r = 1'b0;
        endcase
    end
    
    // LUT for borrow computation based on inputs
    always @(*) begin : borrow_lut
        case({a, b, borrow_in})
            3'b000: borrow_out_r = 1'b0; // No borrow needed
            3'b001: borrow_out_r = 1'b1; // Borrow needed
            3'b010: borrow_out_r = 1'b1; // Borrow needed
            3'b011: borrow_out_r = 1'b1; // Borrow needed
            3'b100: borrow_out_r = 1'b0; // No borrow needed
            3'b101: borrow_out_r = 1'b0; // No borrow needed
            3'b110: borrow_out_r = 1'b0; // No borrow needed
            3'b111: borrow_out_r = 1'b0; // No borrow needed
            default: borrow_out_r = 1'b0;
        endcase
    end
    
    // Connect the internal registers to the outputs
    assign result = result_r;
    assign borrow_out = borrow_out_r;
endmodule

// Constant output module (unchanged)
module Constant_output #(
    parameter WIDTH = 2,
    parameter [WIDTH-1:0] VALUE = {WIDTH{1'b1}}
)(
    output [WIDTH-1:0] y
);
    assign y = VALUE;
endmodule