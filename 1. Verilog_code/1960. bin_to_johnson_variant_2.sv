//SystemVerilog
// Top-level module: Hierarchical bin_to_johnson
module bin_to_johnson #(
    parameter WIDTH = 4
)(
    input  [WIDTH-1:0]        bin_in,
    output [2*WIDTH-1:0]      johnson_out
);

    // Internal signals
    wire [$clog2(2*WIDTH):0]  mod_result;
    wire [2*WIDTH-1:0]        ones_vector;
    wire                      invert_signal;
    wire [2*WIDTH-1:0]        johnson_encoded;

    // Binary to modulo operation submodule
    bin_modulo_baugh_wooley #(
        .WIDTH(WIDTH)
    ) u_bin_modulo (
        .bin_in(bin_in),
        .mod_out(mod_result)
    );

    // Ones-generator submodule (generates the Johnson code before inversion)
    johnson_ones_generator #(
        .WIDTH(WIDTH)
    ) u_ones_gen (
        .pos(mod_result),
        .ones_vec(ones_vector)
    );

    // Invert control logic (decides if output should be inverted)
    assign invert_signal = (mod_result > WIDTH);

    // Output inversion submodule
    johnson_output_inverter #(
        .WIDTH(WIDTH)
    ) u_output_inverter (
        .in_vec(ones_vector),
        .invert(invert_signal),
        .out_vec(johnson_encoded)
    );

    // Final output assignment
    assign johnson_out = johnson_encoded;

endmodule

// -----------------------------------------------------------------------------
// Submodule: bin_modulo_baugh_wooley
// Description: Computes bin_in % (2*WIDTH) using Baugh-Wooley multiplier
// -----------------------------------------------------------------------------
module bin_modulo_baugh_wooley #(
    parameter WIDTH = 4
)(
    input  [WIDTH-1:0]                bin_in,
    output reg [$clog2(2*WIDTH):0]    mod_out
);
    // Baugh-Wooley Multiplier for 8x8 signed multiplication
    function [15:0] baugh_wooley_mult8x8;
        input [7:0] a;
        input [7:0] b;
        integer i, j;
        reg [15:0] partial_products [7:0];
        reg [15:0] temp_sum;
        begin
            // Generate partial products with Baugh-Wooley sign extensions
            for (i = 0; i < 8; i = i + 1) begin
                for (j = 0; j < 8; j = j + 1) begin
                    if (i == 7 && j == 7)
                        partial_products[i][j+i] = ~(a[7] & b[7]); // Sign extension for MSB*MSB
                    else if (i == 7)
                        partial_products[i][j+i] = ~(a[7] & b[j]); // Sign extension for MSB row
                    else if (j == 7)
                        partial_products[i][j+i] = ~(a[i] & b[7]); // Sign extension for MSB column
                    else
                        partial_products[i][j+i] = a[i] & b[j];    // Normal partial product
                end
                // Fill the rest with zeros
                for (j = 0; j < i; j = j + 1)
                    partial_products[i][j] = 1'b0;
                for (j = i+8; j < 16; j = j + 1)
                    partial_products[i][j] = 1'b0;
            end
            // Add correction bits for Baugh-Wooley
            partial_products[7][15] = 1'b1;
            partial_products[7][14] = 1'b1;
            partial_products[6][15] = 1'b1;
            partial_products[5][15] = 1'b1;
            partial_products[4][15] = 1'b1;
            partial_products[3][15] = 1'b1;
            partial_products[2][15] = 1'b1;
            partial_products[1][15] = 1'b1;
            partial_products[0][15] = 1'b1;

            // Sum the partial products
            temp_sum = 16'b0;
            for (i = 0; i < 8; i = i + 1)
                temp_sum = temp_sum + partial_products[i];
            baugh_wooley_mult8x8 = temp_sum;
        end
    endfunction

    wire [7:0] bin_in_ext;
    wire [7:0] modulo_base;
    wire [15:0] quotient_raw;
    wire [7:0] quotient;
    wire [15:0] product_bw;
    wire [7:0] remainder;

    assign bin_in_ext = bin_in;
    assign modulo_base = (2*WIDTH);

    // quotient = bin_in / (2*WIDTH)
    assign quotient_raw = baugh_wooley_div8x8(bin_in_ext, modulo_base);
    assign quotient = quotient_raw[7:0];

    // product_bw = quotient * modulo_base using Baugh-Wooley
    assign product_bw = baugh_wooley_mult8x8(quotient, modulo_base);

    // remainder = bin_in - (quotient * modulo_base)
    assign remainder = bin_in_ext - product_bw[7:0];

    always @(*) begin
        if (bin_in < 2*WIDTH)
            mod_out = bin_in;
        else
            mod_out = remainder;
    end

    // Baugh-Wooley Divider for 8x8 unsigned division (restoring division)
    function [15:0] baugh_wooley_div8x8;
        input [7:0] dividend;
        input [7:0] divisor;
        reg [15:0] quotient;
        reg [15:0] remainder_div;
        integer k;
        begin
            quotient = 0;
            remainder_div = {8'b0, dividend};
            for (k = 0; k < 8; k = k + 1) begin
                remainder_div = remainder_div << 1;
                if (remainder_div[15:8] >= divisor) begin
                    remainder_div[15:8] = remainder_div[15:8] - divisor;
                    quotient = quotient | (16'h1 << (7 - k));
                end
            end
            baugh_wooley_div8x8 = quotient;
        end
    endfunction

endmodule

// -----------------------------------------------------------------------------
// Submodule: johnson_ones_generator
// Description: Generates a vector with 'pos' number of 1's from LSB
// -----------------------------------------------------------------------------
module johnson_ones_generator #(
    parameter WIDTH = 4
)(
    input  [$clog2(2*WIDTH):0]  pos,
    output reg [2*WIDTH-1:0]    ones_vec
);
    integer idx;
    always @(*) begin
        for (idx = 0; idx < 2*WIDTH; idx = idx + 1)
            ones_vec[idx] = (idx < pos) ? 1'b1 : 1'b0;
    end
endmodule

// -----------------------------------------------------------------------------
// Submodule: johnson_output_inverter
// Description: Conditionally inverts the Johnson code output based on 'invert'
// -----------------------------------------------------------------------------
module johnson_output_inverter #(
    parameter WIDTH = 4
)(
    input  [2*WIDTH-1:0]    in_vec,
    input                   invert,
    output [2*WIDTH-1:0]    out_vec
);
    assign out_vec = invert ? ~in_vec : in_vec;
endmodule