//SystemVerilog

// ========================= Top-Level Module ============================
module endian_carry_top #(
    parameter WIDTH = 32,
    parameter BYTE_WIDTH = 8
)(
    // Endian converter interface
    input  [WIDTH-1:0] big_endian_in,
    output [WIDTH-1:0] little_endian_out,
    // Carry lookahead adder interface
    input  [7:0]       adder_operand_a,
    input  [7:0]       adder_operand_b,
    input              adder_carry_in,
    output [7:0]       adder_sum,
    output             adder_carry_out
);

    // Endian converter instantiation
    endian_converter #(
        .WIDTH(WIDTH),
        .BYTE_WIDTH(BYTE_WIDTH)
    ) u_endian_converter (
        .big_endian_in    (big_endian_in),
        .little_endian_out(little_endian_out)
    );

    // Carry lookahead adder instantiation
    carry_lookahead_adder_8bit u_carry_lookahead_adder (
        .operand_a (adder_operand_a),
        .operand_b (adder_operand_b),
        .carry_in  (adder_carry_in),
        .sum       (adder_sum),
        .carry_out (adder_carry_out)
    );

endmodule

// =================== Endian Converter Submodule ========================
// Function: Converts a big-endian input bus to little-endian output bus.
// Parameterized by data width and byte width.
module endian_converter #(
    parameter WIDTH = 32,
    parameter BYTE_WIDTH = 8
)(
    input  [WIDTH-1:0] big_endian_in,
    output [WIDTH-1:0] little_endian_out
);

    genvar byte_idx;
    generate
        for (byte_idx = 0; byte_idx < WIDTH/BYTE_WIDTH; byte_idx = byte_idx + 1) begin: swap
            assign little_endian_out[byte_idx*BYTE_WIDTH +: BYTE_WIDTH] = 
                big_endian_in[(WIDTH/BYTE_WIDTH-1-byte_idx)*BYTE_WIDTH +: BYTE_WIDTH];
        end
    endgenerate

endmodule

// ============ Carry-Lookahead Adder 8-bit Submodules ===================

// -------- Generate/Propagate Bit Calculation Submodule -----------------
// Function: Computes generate and propagate bits for each bit position.
module cla_generate_propagate (
    input  [7:0] operand_a,
    input  [7:0] operand_b,
    output [7:0] generate_bit,
    output [7:0] propagate_bit
);
    assign generate_bit  = operand_a & operand_b;
    assign propagate_bit = operand_a ^ operand_b;
endmodule

// -------- Carry Generation Submodule -----------------------------------
// Function: Computes carry bits using generate/propagate bits and carry in.
module cla_carry_generate (
    input  [7:0] generate_bit,
    input  [7:0] propagate_bit,
    input        carry_in,
    output [7:0] carry,      // carry[0] is carry_in, carry[1..7] are internal carries
    output       carry_out   // final carry out
);
    assign carry[0] = carry_in;
    assign carry[1] = generate_bit[0] | (propagate_bit[0] & carry[0]);
    assign carry[2] = generate_bit[1] | (propagate_bit[1] & generate_bit[0]) | (propagate_bit[1] & propagate_bit[0] & carry[0]);
    assign carry[3] = generate_bit[2] | (propagate_bit[2] & generate_bit[1]) | (propagate_bit[2] & propagate_bit[1] & generate_bit[0]) | (propagate_bit[2] & propagate_bit[1] & propagate_bit[0] & carry[0]);
    assign carry[4] = generate_bit[3] | (propagate_bit[3] & generate_bit[2]) | (propagate_bit[3] & propagate_bit[2] & generate_bit[1]) | (propagate_bit[3] & propagate_bit[2] & propagate_bit[1] & generate_bit[0]) | (propagate_bit[3] & propagate_bit[2] & propagate_bit[1] & propagate_bit[0] & carry[0]);
    assign carry[5] = generate_bit[4] | (propagate_bit[4] & generate_bit[3]) | (propagate_bit[4] & propagate_bit[3] & generate_bit[2]) | (propagate_bit[4] & propagate_bit[3] & propagate_bit[2] & generate_bit[1]) | (propagate_bit[4] & propagate_bit[3] & propagate_bit[2] & propagate_bit[1] & generate_bit[0]) | (propagate_bit[4] & propagate_bit[3] & propagate_bit[2] & propagate_bit[1] & propagate_bit[0] & carry[0]);
    assign carry[6] = generate_bit[5] | (propagate_bit[5] & generate_bit[4]) | (propagate_bit[5] & propagate_bit[4] & generate_bit[3]) | (propagate_bit[5] & propagate_bit[4] & propagate_bit[3] & generate_bit[2]) | (propagate_bit[5] & propagate_bit[4] & propagate_bit[3] & propagate_bit[2] & generate_bit[1]) | (propagate_bit[5] & propagate_bit[4] & propagate_bit[3] & propagate_bit[2] & propagate_bit[1] & generate_bit[0]) | (propagate_bit[5] & propagate_bit[4] & propagate_bit[3] & propagate_bit[2] & propagate_bit[1] & propagate_bit[0] & carry[0]);
    assign carry[7] = generate_bit[6] | (propagate_bit[6] & generate_bit[5]) | (propagate_bit[6] & propagate_bit[5] & generate_bit[4]) | (propagate_bit[6] & propagate_bit[5] & propagate_bit[4] & generate_bit[3]) | (propagate_bit[6] & propagate_bit[5] & propagate_bit[4] & propagate_bit[3] & generate_bit[2]) | (propagate_bit[6] & propagate_bit[5] & propagate_bit[4] & propagate_bit[3] & propagate_bit[2] & generate_bit[1]) | (propagate_bit[6] & propagate_bit[5] & propagate_bit[4] & propagate_bit[3] & propagate_bit[2] & propagate_bit[1] & generate_bit[0]) | (propagate_bit[6] & propagate_bit[5] & propagate_bit[4] & propagate_bit[3] & propagate_bit[2] & propagate_bit[1] & propagate_bit[0] & carry[0]);
    assign carry_out = generate_bit[7] | (propagate_bit[7] & generate_bit[6]) | (propagate_bit[7] & propagate_bit[6] & generate_bit[5]) | (propagate_bit[7] & propagate_bit[6] & propagate_bit[5] & generate_bit[4]) | (propagate_bit[7] & propagate_bit[6] & propagate_bit[5] & propagate_bit[4] & generate_bit[3]) | (propagate_bit[7] & propagate_bit[6] & propagate_bit[5] & propagate_bit[4] & propagate_bit[3] & generate_bit[2]) | (propagate_bit[7] & propagate_bit[6] & propagate_bit[5] & propagate_bit[4] & propagate_bit[3] & propagate_bit[2] & generate_bit[1]) | (propagate_bit[7] & propagate_bit[6] & propagate_bit[5] & propagate_bit[4] & propagate_bit[3] & propagate_bit[2] & propagate_bit[1] & generate_bit[0]) | (propagate_bit[7] & propagate_bit[6] & propagate_bit[5] & propagate_bit[4] & propagate_bit[3] & propagate_bit[2] & propagate_bit[1] & propagate_bit[0] & carry[0]);
endmodule

// -------- Sum Calculation Submodule ------------------------------------
// Function: Computes sum bits from propagate bits and carry bits.
module cla_sum_generate (
    input  [7:0] propagate_bit,
    input  [7:0] carry,
    output [7:0] sum
);
    assign sum = propagate_bit ^ carry;
endmodule

// -------- Top-Level Carry Lookahead Adder Module -----------------------
// Function: 8-bit carry-lookahead addition using submodules.
module carry_lookahead_adder_8bit (
    input  [7:0] operand_a,
    input  [7:0] operand_b,
    input        carry_in,
    output [7:0] sum,
    output       carry_out
);

    wire [7:0] generate_bit;
    wire [7:0] propagate_bit;
    wire [7:0] carry_internal;

    // Generate/propagate bit calculation
    cla_generate_propagate u_cla_generate_propagate (
        .operand_a     (operand_a),
        .operand_b     (operand_b),
        .generate_bit  (generate_bit),
        .propagate_bit (propagate_bit)
    );

    // Carry generation
    cla_carry_generate u_cla_carry_generate (
        .generate_bit (generate_bit),
        .propagate_bit(propagate_bit),
        .carry_in     (carry_in),
        .carry        (carry_internal),
        .carry_out    (carry_out)
    );

    // Sum calculation
    cla_sum_generate u_cla_sum_generate (
        .propagate_bit (propagate_bit),
        .carry         (carry_internal),
        .sum           (sum)
    );

endmodule