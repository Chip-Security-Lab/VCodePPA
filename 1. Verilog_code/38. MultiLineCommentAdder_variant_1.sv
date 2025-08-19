//SystemVerilog
// SystemVerilog
// 8-bit Kogge-Stone Adder - Refactored into submodules

// Module 1: Initial P and G generation
// Calculates initial propagate (a|b), generate (a&b), and propagate-generate (a^b) signals.
module initial_pg_gen #(
    parameter integer WIDTH = 8
) (
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] pg_0, // Propagate-Generate (a^b)
    output wire [WIDTH-1:0] g_0,  // Generate (a&b)
    output wire [WIDTH-1:0] p_0   // Propagate (a|b)
);
    // Simple bitwise operations
    assign pg_0 = a ^ b;
    assign g_0  = a & b;
    assign p_0  = a | b;
endmodule

// Module 2: Kogge-Stone tree computation
// Computes the intermediate and final propagate (P) and generate (G) signals
// using the Kogge-Stone prefix tree structure.
module kogge_stone_tree #(
    parameter integer WIDTH = 8,
    parameter integer STAGES = $clog2(WIDTH) // Number of stages required
) (
    input wire [WIDTH-1:0] g_0, // Initial generate (g[0])
    input wire [WIDTH-1:0] p_0, // Initial propagate (p[0])
    output wire [WIDTH-1:0] final_G, // Final generate (G[STAGES])
    output wire [WIDTH-1:0] final_P  // Final propagate (P[STAGES]) - often computed but not strictly needed for carry/sum
);
    // Intermediate G and P signals for each stage
    // G[s][i], P[s][i] represent the generate/propagate for a block of size 2^s ending at bit i
    wire [STAGES:0][WIDTH-1:0] G;
    wire [STAGES:0][WIDTH-1:0] P;

    // Stage 0: Initial G and P (same as g_0 and p_0)
    genvar i;
    generate
      for (i = 0; i < WIDTH; i = i + 1) begin : gen_stage0_kp
        assign G[0][i] = g_0[i];
        assign P[0][i] = p_0[i];
      end
    endgenerate

    // Kogge-Stone stages (stages 1 through STAGES)
    genvar s;
    generate
      for (s = 1; s <= STAGES; s = s + 1) begin : gen_stages_kp
        localparam integer step = 1 << (s - 1); // Step size for this stage (1, 2, 4, ...)
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_bits_kp
          if (i >= step) begin
            // G[s][i] = G[s-1][i] | (P[s-1][i] & G[s-1][i-step]) - Black cell or Gray cell logic
            assign G[s][i] = G[s-1][i] | (P[s-1][i] & G[s-1][i-step]);
            // P[s][i] = P[s-1][i] & P[s-1][i-step] - Black cell logic
            assign P[s][i] = P[s-1][i] & P[s-1][i-step];
          end else begin
            // For bits less than the current step, G and P are just passed from the previous stage (Gray cell logic)
            assign G[s][i] = G[s-1][i];
            assign P[s][i] = P[s-1][i];
          end
        end
      end
    endgenerate

    // Output the final stage G and P signals
    assign final_G = G[STAGES];
    assign final_P = P[STAGES];
endmodule

// Module 3: Carry calculation
// Calculates the carries into each bit position based on the final G signals from the tree.
module carry_calc #(
    parameter integer WIDTH = 8
) (
    input wire [WIDTH-1:0] final_G, // Final generate signals (G[STAGES])
    output wire [WIDTH:0] c // Carries c[0] to c[WIDTH]
);
    // c[0] is the initial carry-in (assumed 0 for A+B addition)
    assign c[0] = 1'b0;

    // Calculate c[i+1] from final_G[i] for i = 0 to WIDTH-1
    // The carry into bit ci+1 is the final G signal for bit ci
    genvar ci;
    generate
      for (ci = 0; ci < WIDTH; ci = ci + 1) begin : gen_carries_calc
        assign c[ci+1] = final_G[ci];
      end
    endgenerate
    // c[WIDTH] is the final carry-out
endmodule

// Module 4: Sum calculation
// Calculates the sum bits based on the initial propagate-generate and the carries into each bit.
module sum_calc #(
    parameter integer WIDTH = 8
) (
    input wire [WIDTH-1:0] pg_0, // Initial propagate-generate (a^b)
    input wire [WIDTH-1:0] c_in, // Carries into each bit (c[0] to c[WIDTH-1])
    output wire [WIDTH-1:0] sum
);
    // sum[i] = pg_0[i] ^ c[i]
    genvar si;
    generate
      for (si = 0; si < WIDTH; si = si + 1) begin : gen_sum_calc
        assign sum[si] = pg_0[si] ^ c_in[si];
      end
    endgenerate
endmodule


// Top-level module: 8-bit Kogge-Stone Adder
// Instantiates and connects the functional submodules.
module kogge_stone_adder_8bit_top #(
    parameter integer WIDTH = 8,
    parameter integer STAGES = $clog2(WIDTH) // Number of stages for the given width
) (
    input wire [WIDTH-1:0] a, // First operand
    input wire [WIDTH-1:0] b, // Second operand
    output wire [WIDTH-1:0] sum, // Sum output
    output wire      cout // Carry-out
);

    // Internal wires to connect the submodules
    wire [WIDTH-1:0] w_pg_0;    // Wire for initial pg
    wire [WIDTH-1:0] w_g_0;     // Wire for initial g
    wire [WIDTH-1:0] w_p_0;     // Wire for initial p
    wire [WIDTH-1:0] w_final_G; // Wire for final stage G from tree
    wire [WIDTH-1:0] w_final_P; // Wire for final stage P from tree (optional connection)
    wire [WIDTH:0]   w_c;       // Wire for all carries c[0] to c[WIDTH]

    // Instantiate the initial P/G generation module
    initial_pg_gen #(
        .WIDTH(WIDTH)
    ) u_initial_pg_gen (
        .a      (a),
        .b      (b),
        .pg_0   (w_pg_0),
        .g_0    (w_g_0),
        .p_0    (w_p_0)
    );

    // Instantiate the Kogge-Stone tree computation module
    kogge_stone_tree #(
        .WIDTH  (WIDTH),
        .STAGES (STAGES)
    ) u_kogge_stone_tree (
        .g_0     (w_g_0),
        .p_0     (w_p_0),
        .final_G (w_final_G),
        .final_P (w_final_P) // Connected but not used by subsequent modules in this specific adder structure
    );

    // Instantiate the carry calculation module
    carry_calc #(
        .WIDTH(WIDTH)
    ) u_carry_calc (
        .final_G (w_final_G),
        .c       (w_c) // w_c[0] to w_c[WIDTH]
    );

    // Instantiate the sum calculation module
    sum_calc #(
        .WIDTH(WIDTH)
    ) u_sum_calc (
        .pg_0   (w_pg_0),
        .c_in   (w_c[WIDTH-1:0]), // Connect carries c[0] to c[WIDTH-1] as input for sum
        .sum    (sum)
    );

    // Connect the final carry-out
    assign cout = w_c[WIDTH]; // The carry-out is the carry into bit WIDTH

endmodule