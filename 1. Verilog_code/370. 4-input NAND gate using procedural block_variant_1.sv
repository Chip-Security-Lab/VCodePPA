//SystemVerilog
// Top-level module - 4-input NAND gate with pipelined structure
module nand4_6 (
    input  wire A,
    input  wire B, 
    input  wire C, 
    input  wire D, 
    input  wire clk,    // Clock input for pipelining
    input  wire rst_n,  // Active-low reset
    output wire Y
);
    // Pipeline stage signals
    reg  stage1_ab_reg, stage1_cd_reg;
    reg  stage2_and_result_reg;
    wire stage1_ab, stage1_cd;
    wire stage2_and_result;
    
    // Stage 1: Compute partial products AB and CD
    and2_gate and_ab_inst (
        .in_a(A),
        .in_b(B),
        .out_result(stage1_ab)
    );
    
    and2_gate and_cd_inst (
        .in_a(C),
        .in_b(D),
        .out_result(stage1_cd)
    );
    
    // Pipeline registers for stage 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_ab_reg <= 1'b0;
            stage1_cd_reg <= 1'b0;
        end else begin
            stage1_ab_reg <= stage1_ab;
            stage1_cd_reg <= stage1_cd;
        end
    end
    
    // Stage 2: Compute final AND result
    and2_gate and_final_inst (
        .in_a(stage1_ab_reg),
        .in_b(stage1_cd_reg),
        .out_result(stage2_and_result)
    );
    
    // Pipeline register for stage 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_and_result_reg <= 1'b0;
        end else begin
            stage2_and_result_reg <= stage2_and_result;
        end
    end
    
    // Stage 3: Final inversion
    inverter_gate inv_inst (
        .in_value(stage2_and_result_reg),
        .out_value(Y)
    );
    
endmodule

// Optimized primitive gates with standardized interfaces

// 2-input AND gate submodule
module and2_gate (
    input  wire in_a,
    input  wire in_b,
    output wire out_result
);
    assign out_result = in_a & in_b;
endmodule

// Inverter gate submodule
module inverter_gate (
    input  wire in_value,
    output wire out_value
);
    assign out_value = ~in_value;
endmodule