module Adder_3 (
    input clk,
    input rst_n,
    input [3:0] A,
    input [3:0] B,
    output reg [4:0] sum // Pipelined output
);

    // Stage 0: Calculate Generate (G) and Propagate (P) signals
    // These signals are purely combinational from inputs A and B
    wire [3:0] generate_sig_stage0; // G[i] = A[i] & B[i]
    wire [3:0] propagate_sig_stage0; // P[i] = A[i] ^ B[i]

    assign generate_sig_stage0 = A & B;
    assign propagate_sig_stage0 = A ^ B;

    // Register Stage 0 outputs to create the first pipeline stage boundary
    reg [3:0] generate_sig_stage1;
    reg [3:0] propagate_sig_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            generate_sig_stage1 <= 4'b0;
            propagate_sig_stage1 <= 4'b0;
        end else begin
            generate_sig_stage1 <= generate_sig_stage0;
            propagate_sig_stage1 <= propagate_sig_stage0;
        end
    end

    // Stage 1: Calculate Carries and Sum bits
    // This stage uses the registered G and P signals from Stage 0
    wire [4:0] carry_stage1; // carry_stage1[0] is input carry (0), carry_stage1[4] is output carry
    wire [3:0] sum_bits_stage1; // sum_bits_stage1[i] = P_stage1[i] ^ carry_stage1[i]

    // Input carry for the LSB (bit 0) is 0 for simple addition
    assign carry_stage1[0] = 1'b0;

    // Calculate carries using Carry Lookahead logic (expanded form for 4 bits)
    // based on registered G and P signals (generate_sig_stage1, propagate_sig_stage1)
    // carry_stage1[i+1] = G_stage1[i] | (P_stage1[i] & carry_stage1[i])
    assign carry_stage1[1] = generate_sig_stage1[0];
    assign carry_stage1[2] = generate_sig_stage1[1] | (propagate_sig_stage1[1] & generate_sig_stage1[0]);
    assign carry_stage1[3] = generate_sig_stage1[2] | (propagate_sig_stage1[2] & generate_sig_stage1[1]) | (propagate_sig_stage1[2] & propagate_sig_stage1[1] & generate_sig_stage1[0]);
    assign carry_stage1[4] = generate_sig_stage1[3] | (propagate_sig_stage1[3] & generate_sig_stage1[2]) | (propagate_sig_stage1[3] & propagate_sig_stage1[2] & generate_sig_stage1[1]) | (propagate_sig_stage1[3] & propagate_sig_stage1[2] & propagate_sig_stage1[1] & generate_sig_stage1[0]);

    // Calculate sum bits using registered P and calculated carries
    // sum_bits_stage1[i] = P_stage1[i] ^ carry_stage1[i]
    assign sum_bits_stage1[0] = propagate_sig_stage1[0] ^ carry_stage1[0];
    assign sum_bits_stage1[1] = propagate_sig_stage1[1] ^ carry_stage1[1];
    assign sum_bits_stage1[2] = propagate_sig_stage1[2] ^ carry_stage1[2];
    assign sum_bits_stage1[3] = propagate_sig_stage1[3] ^ carry_stage1[3];

    // Combine the carry-out (carry_stage1[4]) and sum bits (sum_bits_stage1[3:0])
    // to form the final 5-bit sum for this stage
    wire [4:0] sum_stage1_output;
    assign sum_stage1_output = {carry_stage1[4], sum_bits_stage1[3:0]};

    // Register the final sum output to create the second pipeline stage boundary
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum <= 5'b0;
        end else begin
            sum <= sum_stage1_output;
        end
    end

endmodule