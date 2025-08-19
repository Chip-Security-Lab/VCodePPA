//SystemVerilog
module dram_dll_calibration #(
    parameter CAL_CYCLES = 128
)(
    input clk,
    input calibrate,
    output reg dll_locked
);

    // Stage 1 registers
    reg [15:0] cal_counter_stage1;
    reg calibrate_stage1;
    
    // Stage 2 registers
    reg [15:0] cal_counter_stage2;
    reg calibrate_stage2;
    
    // Stage 3 registers
    reg [15:0] cal_counter_stage3;
    reg calibrate_stage3;
    
    // Stage 4 registers
    reg [15:0] cal_counter_stage4;
    reg calibrate_stage4;
    
    // Stage 5 registers
    reg [15:0] cal_counter_stage5;
    reg calibrate_stage5;
    
    // Parallel prefix adder implementation
    wire [15:0] sum_stage1;
    wire [15:0] carry_stage1;
    wire [15:0] prop_stage1;
    wire [15:0] gen_stage1;
    
    // Generate and propagate signals
    assign gen_stage1 = cal_counter_stage1 & 16'h0001;
    assign prop_stage1 = cal_counter_stage1 ^ 16'h0001;
    
    // Stage 1: First 4 bits carry computation
    assign carry_stage1[0] = gen_stage1[0];
    assign carry_stage1[1] = gen_stage1[1] | (prop_stage1[1] & gen_stage1[0]);
    assign carry_stage1[2] = gen_stage1[2] | (prop_stage1[2] & gen_stage1[1]) | (prop_stage1[2] & prop_stage1[1] & gen_stage1[0]);
    assign carry_stage1[3] = gen_stage1[3] | (prop_stage1[3] & gen_stage1[2]) | (prop_stage1[3] & prop_stage1[2] & gen_stage1[1]) | (prop_stage1[3] & prop_stage1[2] & prop_stage1[1] & gen_stage1[0]);
    
    // Stage 2: Next 4 bits carry computation
    wire [15:0] carry_stage2;
    assign carry_stage2[4] = gen_stage1[4] | (prop_stage1[4] & carry_stage1[3]);
    assign carry_stage2[5] = gen_stage1[5] | (prop_stage1[5] & carry_stage1[4]);
    assign carry_stage2[6] = gen_stage1[6] | (prop_stage1[6] & carry_stage1[5]);
    assign carry_stage2[7] = gen_stage1[7] | (prop_stage1[7] & carry_stage1[6]);
    
    // Stage 3: Next 4 bits carry computation
    wire [15:0] carry_stage3;
    assign carry_stage3[8] = gen_stage1[8] | (prop_stage1[8] & carry_stage2[7]);
    assign carry_stage3[9] = gen_stage1[9] | (prop_stage1[9] & carry_stage2[8]);
    assign carry_stage3[10] = gen_stage1[10] | (prop_stage1[10] & carry_stage2[9]);
    assign carry_stage3[11] = gen_stage1[11] | (prop_stage1[11] & carry_stage2[10]);
    
    // Stage 4: Final 4 bits carry computation
    wire [15:0] carry_stage4;
    assign carry_stage4[12] = gen_stage1[12] | (prop_stage1[12] & carry_stage3[11]);
    assign carry_stage4[13] = gen_stage1[13] | (prop_stage1[13] & carry_stage3[12]);
    assign carry_stage4[14] = gen_stage1[14] | (prop_stage1[14] & carry_stage3[13]);
    assign carry_stage4[15] = gen_stage1[15] | (prop_stage1[15] & carry_stage3[14]);
    
    // Stage 5: Sum computation
    assign sum_stage1 = prop_stage1 ^ {carry_stage4[14:0], 1'b0};
    
    // Pre-compute locked condition
    wire locked_condition;
    assign locked_condition = calibrate_stage5 && (cal_counter_stage5 == CAL_CYCLES);
    
    always @(posedge clk) begin
        // Stage 1
        cal_counter_stage1 <= calibrate ? cal_counter_stage5 : 0;
        calibrate_stage1 <= calibrate;
        
        // Stage 2
        cal_counter_stage2 <= cal_counter_stage1;
        calibrate_stage2 <= calibrate_stage1;
        
        // Stage 3
        cal_counter_stage3 <= cal_counter_stage2;
        calibrate_stage3 <= calibrate_stage2;
        
        // Stage 4
        cal_counter_stage4 <= cal_counter_stage3;
        calibrate_stage4 <= calibrate_stage3;
        
        // Stage 5
        cal_counter_stage5 <= sum_stage1;
        calibrate_stage5 <= calibrate_stage4;
        
        // Output stage with retimed register
        dll_locked <= locked_condition;
    end
endmodule