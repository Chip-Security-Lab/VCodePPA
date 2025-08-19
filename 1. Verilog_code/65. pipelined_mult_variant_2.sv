//SystemVerilog
module pipelined_mult (
    input clk,
    input [15:0] a, b,
    output reg [31:0] result
);
    // Stage 1 registers
    reg [15:0] a_stage1, b_stage1;
    
    // Stage 2 registers - split multiplication
    reg [7:0] a_high_stage2, a_low_stage2;
    reg [7:0] b_high_stage2, b_low_stage2;
    
    // Stage 3 registers - partial products
    reg [15:0] pp_high_stage3, pp_mid1_stage3, pp_mid2_stage3, pp_low_stage3;
    
    // Stage 4 registers - intermediate sums
    reg [15:0] mid_sum_stage4;
    reg [31:0] high_shift_stage4;
    reg [15:0] low_stage4;
    
    // Stage 5 registers - final accumulation
    reg [31:0] sum_stage5;
    
    // Stage 6 register - final result
    reg [31:0] result_stage6;

    always @(posedge clk) begin
        // Stage 1: Input register
        a_stage1 <= a;
        b_stage1 <= b;
        
        // Stage 2: Split operands
        a_high_stage2 <= a_stage1[15:8];
        a_low_stage2 <= a_stage1[7:0];
        b_high_stage2 <= b_stage1[15:8];
        b_low_stage2 <= b_stage1[7:0];
        
        // Stage 3: Calculate partial products
        pp_high_stage3 <= a_high_stage2 * b_high_stage2;
        pp_mid1_stage3 <= a_high_stage2 * b_low_stage2;
        pp_mid2_stage3 <= a_low_stage2 * b_high_stage2;
        pp_low_stage3 <= a_low_stage2 * b_low_stage2;
        
        // Stage 4: Intermediate calculations
        mid_sum_stage4 <= pp_mid1_stage3 + pp_mid2_stage3;
        high_shift_stage4 <= pp_high_stage3 << 16;
        low_stage4 <= pp_low_stage3;
        
        // Stage 5: Final accumulation
        sum_stage5 <= high_shift_stage4 + (mid_sum_stage4 << 8) + low_stage4;
        
        // Stage 6: Final result
        result_stage6 <= sum_stage5;
        
        // Output assignment
        result <= result_stage6;
    end
endmodule