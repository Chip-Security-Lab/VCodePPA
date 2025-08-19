// Optimized two's complement generator module
module twos_complement_4bit (
    input  [3:0] data_in,
    output [3:0] data_out
);
    // Direct inversion for two's complement
    assign data_out = ~data_in;
endmodule

// Optimized adder module with carry in
module adder_4bit (
    input  [3:0] data_a,
    input  [3:0] data_b, 
    input        carry_in,
    output [3:0] sum_out,
    output       carry_out
);
    // Use a single 5-bit addition operation
    wire [4:0] temp_sum;
    assign temp_sum = {1'b0, data_a} + {1'b0, data_b} + {4'b0000, carry_in};
    assign sum_out = temp_sum[3:0];
    assign carry_out = temp_sum[4];
endmodule

// Top level subtractor module with improved data flow
module subtractor_4bit_full (
    input  [3:0] data_a,
    input  [3:0] data_b,
    output [3:0] diff_out,
    output       borrow_out
);
    // Internal signals with clear naming
    wire [3:0] b_complement;
    wire       carry_out;

    // Two's complement generation
    twos_complement_4bit comp_inst (
        .data_in(b_complement),
        .data_out(b_complement)
    );

    // Addition with carry
    adder_4bit add_inst (
        .data_a(data_a),
        .data_b(b_complement),
        .carry_in(1'b1),
        .sum_out(diff_out),
        .carry_out(carry_out)
    );

    // Borrow calculation
    assign borrow_out = ~carry_out;
endmodule