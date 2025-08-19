//SystemVerilog
// Top-level module with pipelined data path
module nand2_4 (
    input  wire clk,      // Added clock for pipelined operation
    input  wire rst_n,    // Added reset signal
    input  wire A,
    input  wire B,
    output wire Y
);
    // Pipeline stage signals
    wire stage1_a_inv, stage1_b_inv;
    reg  stage2_a_inv, stage2_b_inv;
    wire stage2_nand_result;
    reg  stage3_nand_out;
    
    // Stage 1: Input inversion with signal naming for clear data flow
    input_stage stage1 (
        .in_a(A),
        .in_b(B),
        .out_a_inv(stage1_a_inv),
        .out_b_inv(stage1_b_inv)
    );
    
    // Pipeline registers between stage 1 and 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_a_inv <= 1'b0;
            stage2_b_inv <= 1'b0;
        end else begin
            stage2_a_inv <= stage1_a_inv;
            stage2_b_inv <= stage1_b_inv;
        end
    end
    
    // Stage 2: NAND computation
    nand_stage stage2 (
        .in_a_inv(stage2_a_inv),
        .in_b_inv(stage2_b_inv),
        .out_nand(stage2_nand_result)
    );
    
    // Pipeline register between stage 2 and 3
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage3_nand_out <= 1'b0;
        end else begin
            stage3_nand_out <= stage2_nand_result;
        end
    end
    
    // Stage 3: Output inversion
    output_stage stage3 (
        .in_nand(stage3_nand_out),
        .out_y(Y)
    );
endmodule

// Stage 1: Input signal processing - renamed for clarity
module input_stage (
    input  wire in_a,
    input  wire in_b,
    output wire out_a_inv,
    output wire out_b_inv
);
    // Optimized datapath with clear signal purpose
    assign out_a_inv = ~in_a;  // Invert input A
    assign out_b_inv = ~in_b;  // Invert input B
endmodule

// Stage 2: Core logic operation - renamed for clarity
module nand_stage (
    input  wire in_a_inv,
    input  wire in_b_inv,
    output wire out_nand
);
    // Core computation logic
    assign out_nand = in_a_inv & in_b_inv;
endmodule

// Stage 3: Output signal conditioning - renamed for clarity
module output_stage (
    input  wire in_nand,
    output wire out_y
);
    // Final output transformation
    assign out_y = ~in_nand;
endmodule