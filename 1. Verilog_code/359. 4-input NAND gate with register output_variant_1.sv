//SystemVerilog
// Top-level module that implements a 4-input NAND gate with pipelined structure
module nand4_3 (
    input  wire        clk,      // Clock signal for pipeline registers
    input  wire        rst_n,    // Active low reset
    input  wire        A,
    input  wire        B,
    input  wire        C,
    input  wire        D,
    output wire        Y
);
    // Internal pipeline registers and signals
    reg  stage1_a_reg, stage1_b_reg, stage1_c_reg, stage1_d_reg;
    wire stage1_and_ab, stage1_and_cd;
    reg  stage2_and_ab_reg, stage2_and_cd_reg;
    wire stage2_and_result;
    reg  stage3_and_result_reg;
    
    // Stage 1: Input registration and first level AND operations
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_a_reg <= 1'b0;
            stage1_b_reg <= 1'b0;
            stage1_c_reg <= 1'b0;
            stage1_d_reg <= 1'b0;
        end else begin
            stage1_a_reg <= A;
            stage1_b_reg <= B;
            stage1_c_reg <= C;
            stage1_d_reg <= D;
        end
    end
    
    // First level parallel AND operations
    and2_module and_ab_inst (
        .in_a(stage1_a_reg),
        .in_b(stage1_b_reg),
        .out(stage1_and_ab)
    );
    
    and2_module and_cd_inst (
        .in_a(stage1_c_reg),
        .in_b(stage1_d_reg),
        .out(stage1_and_cd)
    );
    
    // Stage 2: Register first level results and perform second level AND
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_and_ab_reg <= 1'b0;
            stage2_and_cd_reg <= 1'b0;
        end else begin
            stage2_and_ab_reg <= stage1_and_ab;
            stage2_and_cd_reg <= stage1_and_cd;
        end
    end
    
    // Second level AND operation
    and2_module final_and_inst (
        .in_a(stage2_and_ab_reg),
        .in_b(stage2_and_cd_reg),
        .out(stage2_and_result)
    );
    
    // Stage 3: Register final AND result and perform NOT operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage3_and_result_reg <= 1'b0;
        end else begin
            stage3_and_result_reg <= stage2_and_result;
        end
    end
    
    // Final NOT operation to complete NAND functionality
    not_module final_not_inst (
        .in(stage3_and_result_reg),
        .out(Y)
    );
    
endmodule

// 2-input AND gate module with registered outputs for improved timing
module and2_module (
    input  wire in_a,
    input  wire in_b,
    output wire out
);
    // Balanced implementation for minimum delay
    assign out = in_a & in_b;
endmodule

// NOT gate module with optimized implementation
module not_module (
    input  wire in,
    output wire out
);
    // Direct NOT operation
    assign out = ~in;
endmodule