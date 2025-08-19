//SystemVerilog
// Top-level Caesar cipher module with hierarchical structure
module caesar_cipher #(
    parameter SHIFT = 3,
    parameter CHARSET = 26
)(
    input  wire        clk,
    input  wire        enable,
    input  wire [7:0]  char_in,
    output reg  [7:0]  cipher_out
);

    wire        is_lowercase;
    wire [7:0]  char_offset;
    wire [7:0]  shifted_char;

    // Submodule: Character Type Detector
    char_type_detector u_char_type_detector (
        .char_in      (char_in),
        .is_lowercase (is_lowercase)
    );

    // Submodule: Offset Calculator
    char_offset_calc u_char_offset_calc (
        .char_in      (char_in),
        .is_lowercase (is_lowercase),
        .char_offset  (char_offset)
    );

    // Submodule: Caesar Shift with 8-bit Carry Lookahead Adder
    caesar_shift #(
        .SHIFT   (SHIFT),
        .CHARSET (CHARSET)
    ) u_caesar_shift (
        .char_offset  (char_offset),
        .shifted_char (shifted_char)
    );

    // Output logic: explicit multiplexer for output selection
    always @(posedge clk) begin
        if (enable) begin
            case (is_lowercase)
                1'b1: cipher_out <= shifted_char;
                1'b0: cipher_out <= char_in;
                default: cipher_out <= 8'h00;
            endcase
        end
    end

endmodule

// -----------------------------------------------------------------------------
// Submodule: Character Type Detector
// Detects if the input is a lowercase ASCII character ('a' - 'z')
// -----------------------------------------------------------------------------
module char_type_detector (
    input  wire [7:0] char_in,
    output wire       is_lowercase
);
    assign is_lowercase = (char_in >= 8'h61 && char_in <= 8'h7A);
endmodule

// -----------------------------------------------------------------------------
// Submodule: Character Offset Calculator
// Calculates character offset from 'a' if lowercase, else returns 0
// -----------------------------------------------------------------------------
module char_offset_calc (
    input  wire [7:0] char_in,
    input  wire       is_lowercase,
    output wire [7:0] char_offset
);
    reg [7:0] char_offset_mux;
    always @(*) begin
        case (is_lowercase)
            1'b1: char_offset_mux = char_in - 8'h61;
            1'b0: char_offset_mux = 8'h00;
            default: char_offset_mux = 8'h00;
        endcase
    end
    assign char_offset = char_offset_mux;
endmodule

// -----------------------------------------------------------------------------
// Submodule: 8-bit Carry Lookahead Adder (CLA)
// Implements a fast adder for 8-bit inputs
// -----------------------------------------------------------------------------
module cla_adder_8bit (
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire       cin,
    output wire [7:0] sum,
    output wire       cout
);
    wire [7:0] g;  // Generate
    wire [7:0] p;  // Propagate
    wire [8:0] c;  // Carry

    assign g = a & b;
    assign p = a ^ b;
    assign c[0] = cin;
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
    assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);
    assign c[5] = g[4] | (p[4] & g[3]) | (p[4] & p[3] & g[2]) | (p[4] & p[3] & p[2] & g[1]) | (p[4] & p[3] & p[2] & p[1] & g[0]) | (p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
    assign c[6] = g[5] | (p[5] & g[4]) | (p[5] & p[4] & g[3]) | (p[5] & p[4] & p[3] & g[2]) | (p[5] & p[4] & p[3] & p[2] & g[1]) | (p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
    assign c[7] = g[6] | (p[6] & g[5]) | (p[6] & p[5] & g[4]) | (p[6] & p[5] & p[4] & g[3]) | (p[6] & p[5] & p[4] & p[3] & g[2]) | (p[6] & p[5] & p[4] & p[3] & p[2] & g[1]) | (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
    assign c[8] = g[7] | (p[7] & g[6]) | (p[7] & p[6] & g[5]) | (p[7] & p[6] & p[5] & g[4]) | (p[7] & p[6] & p[5] & p[4] & g[3]) | (p[7] & p[6] & p[5] & p[4] & p[3] & g[2]) | (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & g[1]) | (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);

    assign sum = p ^ c[7:0];
    assign cout = c[8];
endmodule

// -----------------------------------------------------------------------------
// Submodule: Caesar Shift
// Shifts the character offset by SHIFT, wraps around CHARSET, and adds 'a'
// Parameterized for shift value and charset size
// Utilizes 8-bit CLA for addition
// -----------------------------------------------------------------------------
module caesar_shift #(
    parameter SHIFT   = 3,
    parameter CHARSET = 26
)(
    input  wire [7:0] char_offset,
    output wire [7:0] shifted_char
);
    wire [7:0] shifted_sum;
    wire       carry_unused;

    // Use CLA adder for fast addition
    cla_adder_8bit u_cla_adder_shift (
        .a    (char_offset),
        .b    (SHIFT[7:0]),
        .cin  (1'b0),
        .sum  (shifted_sum),
        .cout (carry_unused)
    );

    // Explicit multiplexer for modulo operation (for CHARSET=26)
    reg [7:0] shifted_mod_mux;
    always @(*) begin
        if (shifted_sum >= CHARSET)
            shifted_mod_mux = shifted_sum - CHARSET;
        else
            shifted_mod_mux = shifted_sum;
    end

    wire [7:0] shifted_char_sum;
    wire       carry_unused2;

    // Use CLA adder for final addition to 'a'
    cla_adder_8bit u_cla_adder_ascii (
        .a    (shifted_mod_mux),
        .b    (8'h61),
        .cin  (1'b0),
        .sum  (shifted_char_sum),
        .cout (carry_unused2)
    );

    assign shifted_char = shifted_char_sum;
endmodule