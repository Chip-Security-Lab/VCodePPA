//SystemVerilog
// SystemVerilog
// Top-level module for the 8-bit Carry Lookahead Adder
// Instantiates PG, Carry, and Sum generation submodules.
module adder_5 (
    input wire [7:0] a,
    input wire [7:0] b,
    output wire [7:0] sum
);

    // Internal wires to connect submodules
    wire [7:0] p_w;     // Propagate signals from pg_gen
    wire [7:0] g_w;     // Generate signals from pg_gen
    wire [8:0] c_w;     // Carries from carry_chain (c[0]..c[8])
    wire cin_w;         // Carry-in for the adder (c[0])

    // Assume no external carry-in, matching original code
    assign cin_w = 1'b0;

    // Instantiate the PG generation module
    pg_gen_8bit pg_inst (
        .a (a),
        .b (b),
        .p (p_w),
        .g (g_w)
    );

    // Instantiate the Carry chain generation module
    carry_chain_8bit carry_inst (
        .p       (p_w),
        .g       (g_w),
        .cin     (cin_w),
        .carries (c_w)
    );

    // Instantiate the Sum generation module
    // Note: sum_gen_8bit needs c[0] through c[7], which are carries[0] through carries[7] from carry_chain
    sum_gen_8bit sum_inst (
        .p          (p_w),
        .carries_in (c_w[7:0]), // Connect carries[0]..carries[7]
        .sum        (sum)
    );

    // c_w[8] is the final carry-out, not connected to an output port,
    // matching the original module's interface.

endmodule

// Module to generate Propagate (P) and Generate (G) signals
// Inputs: a, b (8-bit operands)
// Outputs: p (Propagate), g (Generate)
module pg_gen_8bit (
    input wire [7:0] a,
    input wire [7:0] b,
    output wire [7:0] p, // Propagate: a[i] ^ b[i]
    output wire [7:0] g  // Generate: a[i] & b[i]
);
    assign p = a ^ b;
    assign g = a & b;
endmodule

// Module to calculate carries using parallel CLA logic
// Inputs: p, g (Propagate/Generate signals), cin (Carry-in for bit 0)
// Outputs: carries (Array of carries, carries[0] is cin, carries[i+1] is carry out of bit i)
module carry_chain_8bit (
    input wire [7:0] p,      // Propagate signals
    input wire [7:0] g,      // Generate signals
    input wire cin,          // Carry-in for bit 0 (c[0])
    output wire [8:0] carries // carries[0] is cin, carries[i+1] is carry out of bit i
);
    // Parallel Carry Lookahead Logic: c[i+1] = G_i | (P_i & c[0])
    // where G_i = g[i] | (p[i] & g[i-1]) | ... | (p[i] & ... & p[1] & g[0])
    // and P_i = p[i] & p[i-1] & ... & p[0]

    assign carries[0] = cin;

    // c[1] = g[0] | (p[0] & c[0])
    assign carries[1] = g[0] | (p[0] & carries[0]);

    // c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0])
    assign carries[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & carries[0]);

    // c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0])
    assign carries[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & carries[0]);

    // c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0])
    assign carries[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & carries[0]);

    // c[5] = g[4] | (p[4] & g[3]) | (p[4] & p[3] & g[2]) | (p[4] & p[3] & p[2] & g[1]) | (p[4] & p[3] & p[2] & p[1] & g[0]) | (p[4] & p[3] & p[2] & p[1] & p[0] & c[0])
    assign carries[5] = g[4] | (p[4] & g[3]) | (p[4] & p[3] & g[2]) | (p[4] & p[3] & p[2] & g[1]) | (p[4] & p[3] & p[2] & p[1] & g[0]) | (p[4] & p[3] & p[2] & p[1] & p[0] & carries[0]);

    // c[6] = g[5] | (p[5] & g[4]) | (p[5] & p[4] & g[3]) | (p[5] & p[4] & p[3] & g[2]) | (p[5] & p[4] & p[3] & p[2] & g[1]) | (p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & c[0])
    assign carries[6] = g[5] | (p[5] & g[4]) | (p[5] & p[4] & g[3]) | (p[5] & p[4] & p[3] & g[2]) | (p[5] & p[4] & p[3] & p[2] & g[1]) | (p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & carries[0]);

    // c[7] = g[6] | (p[6] & g[5]) | (p[6] & p[5] & g[4]) | (p[6] & p[5] & p[4] & g[3]) | (p[6] & p[5] & p[4] & p[3] & g[2]) | (p[6] & p[5] & p[4] & p[3] & p[2] & g[1]) | (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & c[0])
    assign carries[7] = g[6] | (p[6] & g[5]) | (p[6] & p[5] & g[4]) | (p[6] & p[5] & p[4] & g[3]) | (p[6] & p[5] & p[4] & p[3] & g[2]) | (p[6] & p[5] & p[4] & p[3] & p[2] & g[1]) | (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & carries[0]);

    // c[8] = g[7] | (p[7] & g[6]) | (p[7] & p[6] & g[5]) | (p[7] & p[6] & p[5] & g[4]) | (p[7] & p[6] & p[5] & p[4] & g[3]) | (p[7] & p[6] & p[5] & p[4] & p[3] & g[2]) | (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & g[1]) | (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & c[0])
    assign carries[8] = g[7] | (p[7] & g[6]) | (p[7] & p[6] & g[5]) | (p[7] & p[6] & p[5] & g[4]) | (p[7] & p[6] & p[5] & p[4] & g[3]) | (p[7] & p[6] & p[5] & p[4] & p[3] & g[2]) | (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & g[1]) | (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & carries[0]);

endmodule

// Module to generate Sum signals
// Inputs: p (Propagate signals), carries_in (Carries for each bit, c[0]..c[7])
// Outputs: sum (8-bit sum)
module sum_gen_8bit (
    input wire [7:0] p,         // Propagate signals
    input wire [7:0] carries_in, // Carries for each bit (c[0]..c[7])
    output wire [7:0] sum       // Sum: p[i] ^ carries_in[i]
);
    // Sum calculation: sum[i] = p[i] ^ c[i]
    assign sum[0] = p[0] ^ carries_in[0];
    assign sum[1] = p[1] ^ carries_in[1];
    assign sum[2] = p[2] ^ carries_in[2];
    assign sum[3] = p[3] ^ carries_in[3];
    assign sum[4] = p[4] ^ carries_in[4];
    assign sum[5] = p[5] ^ carries_in[5];
    assign sum[6] = p[6] ^ carries_in[6];
    assign sum[7] = p[7] ^ carries_in[7];

endmodule