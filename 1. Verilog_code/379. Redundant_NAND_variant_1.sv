//SystemVerilog
// Top-Level Module: Structured Pipelined Redundant NAND with Dual-Path Verification
module Redundant_NAND(
    input  wire clk,
    input  wire rst_n,
    input  wire a,
    input  wire b,
    output wire y
);

    // Stage 1: Input Registering
    reg a_stage1;
    reg b_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage1 <= 1'b0;
            b_stage1 <= 1'b0;
        end else begin
            a_stage1 <= a;
            b_stage1 <= b;
        end
    end

    // Stage 2: Parallel NAND Computation
    wire nand1_stage2;
    wire nand2_stage2;

    NAND_Path_Pipeline nand_path1 (
        .clk      (clk),
        .rst_n    (rst_n),
        .in1      (a_stage1),
        .in2      (b_stage1),
        .nand_out (nand1_stage2)
    );

    NAND_Path_Pipeline nand_path2 (
        .clk      (clk),
        .rst_n    (rst_n),
        .in1      (a_stage1),
        .in2      (b_stage1),
        .nand_out (nand2_stage2)
    );

    // Stage 3: Registered Verification
    wire y_stage3;

    Dual_Path_Verifier_Pipeline verifier (
        .clk    (clk),
        .rst_n  (rst_n),
        .nand1  (nand1_stage2),
        .nand2  (nand2_stage2),
        .y_out  (y_stage3)
    );

    // Output Register
    reg y_out_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            y_out_reg <= 1'b0;
        else
            y_out_reg <= y_stage3;
    end

    assign y = y_out_reg;

endmodule

// Submodule: Pipelined NAND Path
module NAND_Path_Pipeline (
    input  wire clk,
    input  wire rst_n,
    input  wire in1,
    input  wire in2,
    output wire nand_out
);

    // Pipeline Register Stage
    reg in1_reg;
    reg in2_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in1_reg <= 1'b0;
            in2_reg <= 1'b0;
        end else begin
            in1_reg <= in1;
            in2_reg <= in2;
        end
    end

    // Combinational NAND Logic
    assign nand_out = ~(in1_reg & in2_reg);

endmodule

// Submodule: Pipelined Dual-Path Verifier
module Dual_Path_Verifier_Pipeline (
    input  wire clk,
    input  wire rst_n,
    input  wire nand1,
    input  wire nand2,
    output wire y_out
);

    // Pipeline Register Stage
    reg nand1_reg;
    reg nand2_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            nand1_reg <= 1'b0;
            nand2_reg <= 1'b0;
        end else begin
            nand1_reg <= nand1;
            nand2_reg <= nand2;
        end
    end

    // Combinational AND Logic
    assign y_out = nand1_reg & nand2_reg;

endmodule