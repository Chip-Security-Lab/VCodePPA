//SystemVerilog
// Top module for the split_add function, implemented using a hierarchical ripple-carry adder
// Adds two 8-bit numbers (m, n) and produces a 9-bit sum (total)
// total[8] is the carry-out, total[7:0] is the 8-bit sum
module split_add(
    input wire [7:0] m,
    input wire [7:0] n,
    output wire [8:0] total
);

    // Internal wires to connect the sub-module outputs to the top-level output
    wire [7:0] sum_result;
    wire carry_result;

    // Instantiate the 8-bit ripple carry adder sub-module
    ripple_carry_adder_8bit adder_inst (
        .data_a(m),          // Connect input m to adder's data_a
        .data_b(n),          // Connect input n to adder's data_b
        .sum_out(sum_result), // Connect adder's sum output
        .carry_out(carry_result) // Connect adder's carry-out
    );

    // Concatenate the carry-out and sum result to form the final 9-bit total
    assign total = {carry_result, sum_result};

endmodule

// 8-bit Ripple Carry Adder module
// Adds two 8-bit numbers (data_a, data_b) using 8 1-bit full adders
// Produces an 8-bit sum (sum_out) and a 1-bit carry-out (carry_out)
module ripple_carry_adder_8bit(
    input wire [7:0] data_a,
    input wire [7:0] data_b,
    output wire [7:0] sum_out,
    output wire carry_out
);

    // Internal wires for connecting carries between full adders
    // carry[i] is the carry-out from stage i (adding bits i), which becomes the carry-in for stage i+1
    wire [6:0] internal_carry;

    // Instantiate 8 1-bit full adders
    // Stage 0: Adds LSBs, no carry-in (implicitly 0)
    full_adder_1bit fa0 (
        .a(data_a[0]),
        .b(data_b[0]),
        .cin(1'b0),          // No carry-in for the least significant bit
        .sum(sum_out[0]),
        .cout(internal_carry[0])
    );

    // Stages 1 to 6: Add bits i, taking carry from stage i-1
    full_adder_1bit fa1 ( .a(data_a[1]), .b(data_b[1]), .cin(internal_carry[0]), .sum(sum_out[1]), .cout(internal_carry[1]) );
    full_adder_1bit fa2 ( .a(data_a[2]), .b(data_b[2]), .cin(internal_carry[1]), .sum(sum_out[2]), .cout(internal_carry[2]) );
    full_adder_1bit fa3 ( .a(data_a[3]), .b(data_b[3]), .cin(internal_carry[2]), .sum(sum_out[3]), .cout(internal_carry[3]) );
    full_adder_1bit fa4 ( .a(data_a[4]), .b(data_b[4]), .cin(internal_carry[3]), .sum(sum_out[4]), .cout(internal_carry[4]) );
    full_adder_1bit fa5 ( .a(data_a[5]), .b(data_b[5]), .cin(internal_carry[4]), .sum(sum_out[5]), .cout(internal_carry[5]) );
    full_adder_1bit fa6 ( .a(data_a[6]), .b(data_b[6]), .cin(internal_carry[5]), .sum(sum_out[6]), .cout(internal_carry[6]) );

    // Stage 7: Adds MSBs, taking carry from stage 6
    full_adder_1bit fa7 (
        .a(data_a[7]),
        .b(data_b[7]),
        .cin(internal_carry[6]),
        .sum(sum_out[7]),
        .cout(carry_out)     // Final carry-out
    );

endmodule

// 1-bit Full Adder module
// Adds three 1-bit inputs (a, b, cin) to produce a sum (sum) and a carry-out (cout)
module full_adder_1bit(
    input wire a,
    input wire b,
    input wire cin,
    output wire sum,
    output wire cout
);

    // Sum logic: XOR of all three inputs
    assign sum = a ^ b ^ cin;

    // Carry-out logic: Generate carry if a and b are high OR if cin is high and at least one of a/b is high
    assign cout = (a & b) | (cin & (a ^ b));

endmodule