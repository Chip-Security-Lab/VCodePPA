//SystemVerilog
//===================================================================
// Hierarchical implementation of 4-input NAND gate with pipeline structure
//===================================================================

module nand4_1 (
    input  wire clk,    // Clock input for registering stages
    input  wire rst_n,  // Active-low reset
    input  wire A,      // Input signal A
    input  wire B,      // Input signal B
    input  wire C,      // Input signal C
    input  wire D,      // Input signal D
    output wire Y       // Output - NAND result
);
    // Internal connection signals
    wire stage1_A, stage1_B, stage1_C, stage1_D;
    wire stage2_AB, stage2_CD;
    wire stage3_result;

    // Instantiate input registration stage
    input_register_stage u_input_stage (
        .clk      (clk),
        .rst_n    (rst_n),
        .A        (A),
        .B        (B),
        .C        (C),
        .D        (D),
        .reg_A    (stage1_A),
        .reg_B    (stage1_B),
        .reg_C    (stage1_C),
        .reg_D    (stage1_D)
    );

    // Instantiate partial logic stage
    partial_logic_stage u_partial_stage (
        .clk      (clk),
        .rst_n    (rst_n),
        .A        (stage1_A),
        .B        (stage1_B),
        .C        (stage1_C),
        .D        (stage1_D),
        .AB_and   (stage2_AB),
        .CD_and   (stage2_CD)
    );

    // Instantiate output logic stage
    output_logic_stage u_output_stage (
        .clk      (clk),
        .rst_n    (rst_n),
        .AB_and   (stage2_AB),
        .CD_and   (stage2_CD),
        .nand_out (stage3_result)
    );

    // Assign registered output
    assign Y = stage3_result;

endmodule

//===================================================================
// Stage 1: Register and synchronize input signals
//===================================================================
module input_register_stage #(
    parameter RESET_VALUE = 1'b0
)(
    input  wire clk,     // Clock input
    input  wire rst_n,   // Active-low reset
    input  wire A,       // Input signal A
    input  wire B,       // Input signal B
    input  wire C,       // Input signal C
    input  wire D,       // Input signal D
    output reg  reg_A,   // Registered A
    output reg  reg_B,   // Registered B
    output reg  reg_C,   // Registered C
    output reg  reg_D    // Registered D
);

    // Register all input signals on clock edge
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_A <= RESET_VALUE;
            reg_B <= RESET_VALUE;
            reg_C <= RESET_VALUE;
            reg_D <= RESET_VALUE;
        end else begin
            reg_A <= A;
            reg_B <= B;
            reg_C <= C;
            reg_D <= D;
        end
    end

endmodule

//===================================================================
// Stage 2: Compute partial AND operations
//===================================================================
module partial_logic_stage #(
    parameter RESET_VALUE = 1'b0
)(
    input  wire clk,     // Clock input
    input  wire rst_n,   // Active-low reset
    input  wire A,       // Registered input A
    input  wire B,       // Registered input B
    input  wire C,       // Registered input C
    input  wire D,       // Registered input D
    output reg  AB_and,  // A AND B result
    output reg  CD_and   // C AND D result
);

    // Compute and register partial products
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            AB_and <= RESET_VALUE;
            CD_and <= RESET_VALUE;
        end else begin
            AB_and <= A & B;
            CD_and <= C & D;
        end
    end

endmodule

//===================================================================
// Stage 3: Final NAND computation
//===================================================================
module output_logic_stage #(
    parameter RESET_VALUE = 1'b1  // Default NAND output is 1
)(
    input  wire clk,      // Clock input
    input  wire rst_n,    // Active-low reset
    input  wire AB_and,   // A AND B result
    input  wire CD_and,   // C AND D result
    output reg  nand_out  // Final NAND output
);

    // Compute final NAND operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            nand_out <= RESET_VALUE;
        end else begin
            nand_out <= ~(AB_and & CD_and);
        end
    end

endmodule