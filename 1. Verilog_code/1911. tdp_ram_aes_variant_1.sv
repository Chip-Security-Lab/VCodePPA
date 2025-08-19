//SystemVerilog, IEEE 1364-2005 Standard
module AdaptiveThreshold #(parameter WIDTH=8, ALPHA=3) (
    input clk,
    input rst,
    input valid_in,
    input [WIDTH-1:0] adc_input,
    output reg digital_out,
    output reg valid_out
);
    // Pipeline stage registers
    reg [WIDTH-1:0] adc_input_stage1;
    reg [WIDTH+ALPHA-1:0] avg_level;
    reg [WIDTH-1:0] threshold;
    reg [WIDTH-1:0] adc_input_stage2;
    reg [WIDTH-1:0] threshold_stage2;
    
    // Valid signal pipeline registers
    reg valid_stage1;
    reg valid_stage2;
    
    // Pipeline Stage 1: Calculate threshold and update average level
    always @(posedge clk) begin
        if (rst) begin
            avg_level <= 0;
            threshold <= 0;
            valid_stage1 <= 0;
            adc_input_stage1 <= 0;
        end else begin
            valid_stage1 <= valid_in;
            
            if (valid_in) begin
                // Store input for next stage
                adc_input_stage1 <= adc_input;
                
                // Calculate threshold for current cycle
                threshold <= avg_level >> ALPHA;
                
                // Update average level using current threshold
                avg_level <= avg_level + (adc_input - (avg_level >> ALPHA));
            end
        end
    end
    
    // Pipeline Stage 2: Register threshold and input for comparison
    always @(posedge clk) begin
        if (rst) begin
            threshold_stage2 <= 0;
            adc_input_stage2 <= 0;
            valid_stage2 <= 0;
        end else begin
            valid_stage2 <= valid_stage1;
            
            if (valid_stage1) begin
                threshold_stage2 <= threshold;
                adc_input_stage2 <= adc_input_stage1;
            end
        end
    end
    
    // Pipeline Stage 3: Compare input with threshold
    always @(posedge clk) begin
        if (rst) begin
            digital_out <= 0;
            valid_out <= 0;
        end else begin
            valid_out <= valid_stage2;
            
            if (valid_stage2) begin
                digital_out <= adc_input_stage2 > threshold_stage2;
            end
        end
    end
endmodule