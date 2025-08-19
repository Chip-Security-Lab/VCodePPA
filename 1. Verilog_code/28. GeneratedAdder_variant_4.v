module Adder_6(
    input wire clk,
    input wire rst_n,
    input wire [3:0] A,
    input wire [3:0] B,
    output wire [4:0] sum
);

    // Stage 1: Calculate Generate and Propagate signals (Combinational)
    // These signals are computed directly from the inputs A and B.
    wire [3:0] G_s1; // Generate: G_s1[i] = A[i] & B[i]
    wire [3:0] P_s1; // Propagate: P_s1[i] = A[i] ^ B[i]

    assign G_s1[0] = A[0] & B[0];
    assign P_s1[0] = A[0] ^ B[0];

    assign G_s1[1] = A[1] & B[1];
    assign P_s1[1] = A[1] ^ B[1];

    assign G_s1[2] = A[2] & B[2];
    assign P_s1[2] = A[2] ^ B[2];

    assign G_s1[3] = A[3] & B[3];
    assign P_s1[3] = A[3] ^ B[3];

    // Stage 1 Registers: Register G and P for the next stage.
    reg [3:0] G_r1;
    reg [3:0] P_r1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            G_r1 <= 4'b0;
            P_r1 <= 4'b0;
        end else begin
            G_r1 <= G_s1;
            P_r1 <= P_s1;
        end
    end

    // Stage 2: Calculate Carries based on registered G and P (Combinational)
    // This stage computes the carry signals based on the results from Stage 1.
    wire [4:0] C_s2; // C_s2[0] is input carry, C_s2[4] is output carry for this stage

    // Assume input carry C[0] is 0 for standard addition
    assign C_s2[0] = 1'b0; // Constant input carry for the first bit position

    // Calculate carries using ripple logic within this stage
    // C_s2[i+1] = G_r1[i] | (P_r1[i] & C_s2[i])
    assign C_s2[1] = G_r1[0] | (P_r1[0] & C_s2[0]);
    assign C_s2[2] = G_r1[1] | (P_r1[1] & C_s2[1]);
    assign C_s2[3] = G_r1[2] | (P_r1[2] & C_s2[2]);
    assign C_s2[4] = G_r1[3] | (P_r1[3] & C_s2[3]); // Final carry-out of this stage

    // Stage 2 Registers: Register Carries for the next stage.
    reg [4:0] C_r2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            C_r2 <= 5'b0;
        end else begin
            C_r2 <= C_s2;
        end
    end

    // Stage 3: Calculate Sum bits based on registered P and C (Combinational)
    // This stage computes the final sum bits.
    wire [4:0] sum_s3;

    // sum_s3[i] = P_r1[i] ^ C_r2[i]
    assign sum_s3[0] = P_r1[0] ^ C_r2[0];
    assign sum_s3[1] = P_r1[1] ^ C_r2[1];
    assign sum_s3[2] = P_r1[2] ^ C_r2[2];
    assign sum_s3[3] = P_r1[3] ^ C_r2[3];

    // The carry-out from Stage 2 is the most significant bit of the sum
    assign sum_s3[4] = C_r2[4];

    // Stage 3 Registers: Register Final Sum (Output Register)
    reg [4:0] sum_r3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_r3 <= 5'b0;
        end else begin
            sum_r3 <= sum_s3;
        end
    end

    // Output assignment: The final output is the registered sum.
    assign sum = sum_r3;

endmodule