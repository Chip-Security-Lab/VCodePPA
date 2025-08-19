//SystemVerilog
// full_adder_cell module: Performs 1-bit binary addition with carry-in
// Computes the sum and carry-out for two single-bit inputs and a carry-in.
module full_adder_cell (
    input wire a_i,     // First input bit
    input wire b_i,     // Second input bit
    input wire cin_i,   // Carry-in bit
    output wire sum_o,  // Sum output bit
    output wire cout_o  // Carry-out bit
);

    // Intermediate signals for generate and propagate
    wire p; // Propagate: a_i XOR b_i
    wire g; // Generate: a_i AND b_i

    // Calculate propagate and generate signals
    assign p = a_i ^ b_i;
    assign g = a_i & b_i;

    // Sum is the XOR of propagate and carry-in
    assign sum_o = p ^ cin_i;

    // Carry-out is generate OR (propagate AND carry-in)
    assign cout_o = g | (p & cin_i);

endmodule


// ripple_carry_adder_8bit module: Performs 8-bit binary addition
// Implements an 8-bit adder using the ripple-carry algorithm,
// instantiating 8 full_adder_cell modules.
module ripple_carry_adder_8bit (
    input wire [7:0] a_i,   // First 8-bit input operand
    input wire [7:0] b_i,   // Second 8-bit input operand
    input wire cin_i,       // Carry-in bit for the LSB
    output wire [7:0] sum_o,// 8-bit sum output
    output wire cout_o      // Carry-out bit from the MSB
);

    // Internal wire to connect carry bits between full adder stages.
    // carry[0] is cin_i, carry[1] is the carry-out of bit 0, ..., carry[8] is the carry-out of bit 7.
    wire [8:0] carry;

    // Connect the overall carry-in to the first stage's carry-in
    assign carry[0] = cin_i;

    // Instantiate 8 full_adder_cell modules for each bit position (0 to 7)
    // The carry signal ripples from the carry-out of stage i to the carry-in of stage i+1.
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : adder_stage
            full_adder_cell u_full_adder (
                .a_i(a_i[i]),       // Connect i-th bit of the first operand
                .b_i(b_i[i]),       // Connect i-th bit of the second operand
                .cin_i(carry[i]),   // Connect carry-in from the previous stage (or overall cin for i=0)
                .sum_o(sum_o[i]),   // Connect sum output to the i-th bit of the total sum
                .cout_o(carry[i+1]) // Connect carry-out to the next stage's carry-in
            );
        end
    endgenerate

    // The overall carry-out is the carry-out of the last stage (bit 7)
    assign cout_o = carry[8];

endmodule