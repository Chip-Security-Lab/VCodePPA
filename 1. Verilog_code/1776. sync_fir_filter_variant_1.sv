//SystemVerilog
module sync_fir_filter #(
    parameter DATA_W = 12,
    parameter TAP_W = 8,
    parameter TAPS = 4
)(
    input clk, rst,
    input [DATA_W-1:0] sample_in,
    input [TAP_W-1:0] coeffs [TAPS-1:0],
    output reg [DATA_W+TAP_W-1:0] filtered_out
);
    // Delay line registers
    reg [DATA_W-1:0] delay_line [TAPS-1:0];
    
    // Pipeline registers for partial products
    reg [DATA_W+TAP_W-1:0] mul_results [TAPS-1:0];
    
    // Pipeline registers for accumulation stages
    reg [DATA_W+TAP_W-1:0] acc_stage1;
    reg [DATA_W+TAP_W-1:0] acc_stage2;
    
    // Valid signal propagation through pipeline
    reg valid_stage1, valid_stage2, valid_stage3;
    
    integer i;
    
    always @(posedge clk) begin
        if (rst) begin
            // Reset delay line
            for (i = 0; i < TAPS; i = i + 1) begin
                delay_line[i] <= 0;
                mul_results[i] <= 0;
            end
            
            // Reset pipeline registers
            acc_stage1 <= 0;
            acc_stage2 <= 0;
            filtered_out <= 0;
            
            // Reset valid signals
            valid_stage1 <= 0;
            valid_stage2 <= 0;
            valid_stage3 <= 0;
        end else begin
            // Stage 0: Input and delay line update
            for (i = TAPS-1; i > 0; i = i - 1)
                delay_line[i] <= delay_line[i-1];
            delay_line[0] <= sample_in;
            valid_stage1 <= 1; // Data is always valid in this design
            
            // Stage 1: Multiplication
            for (i = 0; i < TAPS; i = i + 1)
                mul_results[i] <= delay_line[i] * coeffs[i];
            valid_stage2 <= valid_stage1;
            
            // Stage 2: First accumulation stage
            acc_stage1 <= mul_results[0] + mul_results[1];
            acc_stage2 <= mul_results[2] + mul_results[3];
            valid_stage3 <= valid_stage2;
            
            // Stage 3: Final accumulation and output
            filtered_out <= acc_stage1 + acc_stage2;
        end
    end
endmodule