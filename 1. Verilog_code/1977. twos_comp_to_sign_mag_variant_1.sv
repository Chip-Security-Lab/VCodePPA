//SystemVerilog
module twos_comp_to_sign_mag #(
    parameter WIDTH = 16
)(
    input  wire [WIDTH-1:0] twos_comp_in,
    output reg  [WIDTH-1:0] sign_mag_out
);

    // Internal signals
    wire sign_bit;
    wire [WIDTH-2:0] input_magnitude;
    wire [7:0] operand_a;
    wire [7:0] operand_b;
    wire condition;
    wire [7:0] diff_cond_inv;
    wire [WIDTH-2:0] negative_magnitude;

    // Assign sign bit
    assign sign_bit = twos_comp_in[WIDTH-1];

    // Assign magnitude (excluding sign bit)
    assign input_magnitude = twos_comp_in[WIDTH-2:0];

    // Condition for conditional inversion: if sign_bit is 1, subtract input_magnitude[7:0] from 0 with conditional inversion
    assign condition = sign_bit;

    // Conditional inversion for conditional subtractor
    assign operand_a = 8'b0;
    assign operand_b = condition ? ~input_magnitude[7:0] : input_magnitude[7:0];

    // Conditional inversion subtractor algorithm
    cond_inv_subtractor_8bit u_cond_inv_subtractor_8bit (
        .a             (operand_a),
        .b             (operand_b),
        .sub_invert    (condition),
        .difference    (diff_cond_inv)
    );

    // Compose negative magnitude for sign-magnitude conversion
    assign negative_magnitude = { {(WIDTH-9){1'b0}}, diff_cond_inv } + (condition ? 1'b1 : 1'b0);

    // Assign sign bit of output
    always @(*) begin
        sign_mag_out[WIDTH-1] = sign_bit;
    end

    // Assign magnitude bits of output
    always @(*) begin
        if (sign_bit)
            sign_mag_out[WIDTH-2:0] = negative_magnitude;
        else
            sign_mag_out[WIDTH-2:0] = input_magnitude;
    end

endmodule

module cond_inv_subtractor_8bit (
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire       sub_invert, // 1: subtraction (a - b), 0: addition (a + b)
    output wire [7:0] difference
);
    wire [7:0] b_xor;
    wire [7:0] sum;
    wire       carry_out;

    // Conditional inversion: b ^ {8{sub_invert}}
    assign b_xor = b ^ {8{sub_invert}};

    // Conditional adder: a + b_xor + sub_invert
    assign {carry_out, sum} = {1'b0, a} + {1'b0, b_xor} + sub_invert;

    assign difference = sum;

endmodule