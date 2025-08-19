//SystemVerilog
module HysteresisFilter #(parameter W=8, HYST=4) (
    input clk,
    input rst,  // Added reset signal for pipeline control
    input valid_in,  // Input valid signal
    input [W-1:0] din,
    output reg out,
    output reg valid_out  // Output valid signal
);
    // Pipeline stage 1 registers
    reg [W-1:0] din_stage1;
    reg [W-1:0] prev_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 registers
    reg gt_threshold_stage2;
    reg lt_threshold_stage2;
    reg [W-1:0] din_stage2;
    reg valid_stage2;
    
    // Stage 1: Register inputs and prepare for comparison
    always @(posedge clk) begin
        if (rst) begin
            din_stage1 <= 0;
            prev_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            din_stage1 <= din;
            prev_stage1 <= prev_stage1;  // Maintain previous value
            valid_stage1 <= valid_in;
            
            // Update prev_stage1 when we complete a calculation
            if (valid_stage2)
                prev_stage1 <= din_stage2;
        end
    end
    
    // Stage 2: Perform comparisons and register results
    always @(posedge clk) begin
        if (rst) begin
            gt_threshold_stage2 <= 0;
            lt_threshold_stage2 <= 0;
            din_stage2 <= 0;
            valid_stage2 <= 0;
        end else begin
            gt_threshold_stage2 <= din_stage1 > prev_stage1 + HYST;
            lt_threshold_stage2 <= din_stage1 < prev_stage1 - HYST;
            din_stage2 <= din_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: Update output based on comparison results
    always @(posedge clk) begin
        if (rst) begin
            out <= 0;
            valid_out <= 0;
        end else begin
            valid_out <= valid_stage2;
            
            if (valid_stage2) begin
                if (gt_threshold_stage2)
                    out <= 1;
                else if (lt_threshold_stage2)
                    out <= 0;
            end
        end
    end
endmodule