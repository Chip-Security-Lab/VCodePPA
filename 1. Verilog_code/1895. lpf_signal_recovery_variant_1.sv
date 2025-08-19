//SystemVerilog
module lpf_signal_recovery #(
    parameter WIDTH = 12,
    parameter ALPHA = 4 // Alpha/16 portion of new sample
)(
    input wire clock,
    input wire reset,
    input wire [WIDTH-1:0] raw_sample,
    output wire [WIDTH-1:0] filtered
);
    // Register the input sample
    reg [WIDTH-1:0] raw_sample_reg;
    
    // Pre-computation registers
    reg [WIDTH+4:0] alpha_x_raw_reg;
    reg [WIDTH+4:0] one_minus_alpha_x_filtered_reg;
    
    // Computational pipeline registers
    reg [WIDTH+4:0] sum_result_reg;
    reg [WIDTH+4:0] barrel_shift_stage1_reg;
    reg [WIDTH+4:0] barrel_shift_stage2_reg;
    reg [WIDTH+4:0] filtered_internal;
    
    // Register input
    always @(posedge clock) begin
        if (reset)
            raw_sample_reg <= 0;
        else
            raw_sample_reg <= raw_sample;
    end
    
    // Feedback path for filtered output (moved register)
    wire [WIDTH-1:0] filtered_feedback = filtered_internal[WIDTH-1:0];
    
    // Compute alpha * raw_sample (first stage)
    wire [WIDTH+4:0] alpha_x_raw = ALPHA * raw_sample_reg;
    
    // Compute (16-ALPHA) * filtered (first stage)
    wire [WIDTH+4:0] one_minus_alpha_x_filtered = (16-ALPHA) * filtered_feedback;
    
    // Register first computation stage
    always @(posedge clock) begin
        if (reset) begin
            alpha_x_raw_reg <= 0;
            one_minus_alpha_x_filtered_reg <= 0;
        end
        else begin
            alpha_x_raw_reg <= alpha_x_raw;
            one_minus_alpha_x_filtered_reg <= one_minus_alpha_x_filtered;
        end
    end
    
    // Compute sum (second stage)
    wire [WIDTH+4:0] sum_result = one_minus_alpha_x_filtered_reg + alpha_x_raw_reg;
    
    // Register sum result
    always @(posedge clock) begin
        if (reset)
            sum_result_reg <= 0;
        else
            sum_result_reg <= sum_result;
    end
    
    // Barrel shifter - first stage (divide by 2)
    wire [WIDTH+4:0] barrel_shift_stage1 = 4'b0001 & 1'b1 ? {1'b0, sum_result_reg[WIDTH+4:1]} : sum_result_reg;
    
    // Register first barrel shift stage
    always @(posedge clock) begin
        if (reset)
            barrel_shift_stage1_reg <= 0;
        else
            barrel_shift_stage1_reg <= barrel_shift_stage1;
    end
    
    // Barrel shifter - second stage (divide by 4)
    wire [WIDTH+4:0] barrel_shift_stage2 = 4'b0010 & 1'b1 ? {2'b00, barrel_shift_stage1_reg[WIDTH+4:2]} : barrel_shift_stage1_reg;
    
    // Register second barrel shift stage
    always @(posedge clock) begin
        if (reset)
            barrel_shift_stage2_reg <= 0;
        else
            barrel_shift_stage2_reg <= barrel_shift_stage2;
    end
    
    // Barrel shifter - remaining stages (not doing actual shifts based on original conditions)
    wire [WIDTH+4:0] barrel_shift_stage3 = 4'b0100 & 1'b0 ? {4'b0000, barrel_shift_stage2_reg[WIDTH+4:4]} : barrel_shift_stage2_reg;
    wire [WIDTH+4:0] barrel_shift_stage4 = 4'b1000 & 1'b0 ? {8'b00000000, barrel_shift_stage3[WIDTH+4:8]} : barrel_shift_stage3;
    
    // Final stage register
    always @(posedge clock) begin
        if (reset)
            filtered_internal <= 0;
        else
            filtered_internal <= barrel_shift_stage4;
    end
    
    // Connect to output
    assign filtered = filtered_internal[WIDTH-1:0];
    
endmodule