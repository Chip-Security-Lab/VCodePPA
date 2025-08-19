module adder_optimized #(parameter N=8)(
    input [N-1:0] a,b,
    input cin,
    output [N-1:0] sum,
    output cout
);

    // Implementation using cascaded 2-bit Manchester-like adder blocks
    // N must be a multiple of 2

    // Internal carries between blocks
    // block_carry[0] is cin, block_carry[i+1] is carry out of block i
    wire [N/2:0] block_carry;

    assign block_carry[0] = cin;

    // Instantiate 2-bit Manchester blocks
    genvar j;
    generate
        if (N % 2 != 0) begin : error_N_must_be_even
            // Synthesis tools may not support $error in generate
            // Use a synthesis constraint or assertion instead for real design
            // $error("Parameter N must be a multiple of 2 for this adder structure.");
        end else begin : block_instantiation
            for (j = 0; j < N/2; j = j + 1) begin : block_gen
                manchester_adder_2bit block (
                    .a(a[j*2 + 1 : j*2]),
                    .b(b[j*2 + 1 : j*2]),
                    .cin(block_carry[j]),
                    .sum(sum[j*2 + 1 : j*2]),
                    .cout(block_carry[j+1])
                );
            end
        end
    endgenerate

    // The final carry out is the carry out of the last block
    assign cout = block_carry[N/2];

endmodule

// Submodule implementing a 2-bit Manchester-like adder block
module manchester_adder_2bit(
    input [1:0] a, b,
    input cin,
    output [1:0] sum,
    output cout
);

    // Implementation of a 2-bit adder using Manchester carry logic

    wire [1:0] p, g;
    // c[0]=cin, c[1]=carry out of bit 0, c[2]=carry out of bit 1 (cout)
    wire [2:0] c;

    // Generate and Propagate signals
    assign p = a ^ b;
    assign g = a & b;

    // Carry chain within the 2-bit block
    assign c[0] = cin;
    assign c[1] = g[0] | (p[0] & c[0]); // Carry out of bit 0
    assign c[2] = g[1] | (p[1] & c[1]); // Carry out of bit 1 (block cout)

    // Sum signals
    assign sum[0] = p[0] ^ c[0];
    assign sum[1] = p[1] ^ c[1];

    // Block carry out
    assign cout = c[2];

endmodule