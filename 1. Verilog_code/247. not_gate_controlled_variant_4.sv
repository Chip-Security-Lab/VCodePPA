//SystemVerilog
module parallel_prefix_adder_9bit (
    input wire [8:0] A,
    input wire [8:0] B,
    input wire cin,
    output wire [8:0] Y,
    output wire cout
);

    wire [8:0] G, P;
    wire [9:0] C; // C[0] is cin, C[1] to C[9] are carries

    // Generate and Propagate signals
    genvar i;
    for (i = 0; i < 9; i = i + 1) begin
        assign G[i] = A[i] & B[i];
        assign P[i] = A[i] ^ B[i];
    end

    assign C[0] = cin;

    // Parallel Prefix Tree (Brent-Kung style)
    // Use intermediate signals to avoid multiple assignments to the same wire
    wire [8:0] G_lvl1, P_lvl1;
    wire [8:0] G_lvl2, P_lvl2;
    wire [8:0] G_lvl3, P_lvl3;

    // Level 1
    for (i = 0; i < 9; i = i + 1) begin
        if (i % 2 == 1) begin
            assign G_lvl1[i] = G[i] | (P[i] & G[i-1]);
            assign P_lvl1[i] = P[i] & P[i-1];
        end else begin
            assign G_lvl1[i] = G[i];
            assign P_lvl1[i] = P[i];
        end
    end

    // Level 2
    for (i = 0; i < 9; i = i + 1) begin
        if (i % 4 >= 2) begin
             assign G_lvl2[i] = G_lvl1[i] | (P_lvl1[i] & G_lvl1[i-2]);
             assign P_lvl2[i] = P_lvl1[i] & P_lvl1[i-2];
        end else begin
             assign G_lvl2[i] = G_lvl1[i];
             assign P_lvl2[i] = P_lvl1[i];
        end
    end

    // Level 3
     for (i = 0; i < 9; i = i + 1) begin
        if (i % 8 >= 4) begin
             assign G_lvl3[i] = G_lvl2[i] | (P_lvl2[i] & G_lvl2[i-4]);
             assign P_lvl3[i] = P_lvl2[i] & P_lvl2[i-4];
        end else begin
             assign G_lvl3[i] = G_lvl2[i];
             assign P_lvl3[i] = P_lvl2[i];
        end
    end

    // Calculate carries using prefix results
    assign C[1] = G[0] | (P[0] & C[0]);
    assign C[2] = G_lvl1[1] | (P_lvl1[1] & C[0]);
    assign C[3] = G[2] | (P[2] & C[2]);
    assign C[4] = G_lvl2[3] | (P_lvl2[3] & C[0]);
    assign C[5] = G[4] | (P[4] & C[4]);
    assign C[6] = G_lvl1[5] | (P_lvl1[5] & C[4]);
    assign C[7] = G[6] | (P[6] & C[6]);
    assign C[8] = G_lvl3[7] | (P_lvl3[7] & C[0]);
    assign C[9] = G[8] | (P[8] & C[8]);


    // Sum calculation
    for (i = 0; i < 9; i = i + 1) begin
        assign Y[i] = P[i] ^ C[i];
    end

    assign cout = C[9];

endmodule

module parallel_prefix_subtractor_8bit_optimized (
    input wire [7:0] A,
    input wire [7:0] B,
    output wire [7:0] Y
);

    wire [7:0] B_inv;
    wire [8:0] A_ext, B_inv_ext, sum_result;
    wire cout;

    assign B_inv = ~B;

    // Extend inputs to 9 bits for subtraction (A + ~B + 1)
    assign A_ext = {1'b0, A};
    assign B_inv_ext = {1'b0, B_inv};

    // Instantiate the 9-bit parallel prefix adder
    parallel_prefix_adder_9bit adder_inst (
        .A(A_ext),
        .B(B_inv_ext),
        .cin(1'b1), // Carry-in is 1 for subtraction (A + ~B + 1)
        .Y(sum_result),
        .cout(cout) // cout is not used for the 8-bit result
    );

    // The 8-bit result is the lower 8 bits of the 9-bit sum
    assign Y = sum_result[7:0];

endmodule


module not_gate_controlled_optimized #(
    parameter WIDTH = 8
)(
    input wire [WIDTH-1:0] A,
    input wire [WIDTH-1:0] B, // Assuming B is the input for subtraction
    input wire control,
    output wire [WIDTH-1:0] Y
);

    wire [WIDTH-1:0] subtracted_result;

    // Instantiate the parallel prefix subtractor
    // Note: The optimized subtractor is hardcoded for 8 bits,
    // so the WIDTH parameter is not directly used in the instance.
    parallel_prefix_subtractor_8bit_optimized subtractor_inst (
        .A(A),
        .B(B),
        .Y(subtracted_result)
    );

    // Original logic for controlling the output
    assign Y = control ? subtracted_result : A;

endmodule