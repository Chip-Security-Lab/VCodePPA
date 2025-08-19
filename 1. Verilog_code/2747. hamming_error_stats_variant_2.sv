//SystemVerilog
module hamming_error_stats(
    input clk, rst,
    input [6:0] code_in,
    output reg [3:0] data_out,
    output reg error_detected,
    output reg [7:0] total_errors,
    output reg [7:0] corrected_errors
);
    // Stage 1: Calculate syndrome bits and register input
    reg [6:0] code_stage1;
    reg [2:0] syndrome_stage1;
    
    // Stage 2: Error detection and correction
    reg [2:0] syndrome_stage2;
    reg [3:0] data_stage2;
    reg error_detected_stage2;
    
    // Stage 3: Counter update logic
    reg error_detected_stage3;
    reg [2:0] syndrome_stage3;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset stage 1
            code_stage1 <= 7'b0;
            syndrome_stage1 <= 3'b0;
            
            // Reset stage 2
            syndrome_stage2 <= 3'b0;
            data_stage2 <= 4'b0;
            error_detected_stage2 <= 1'b0;
            
            // Reset stage 3
            error_detected_stage3 <= 1'b0;
            syndrome_stage3 <= 3'b0;
            
            // Reset outputs
            data_out <= 4'b0;
            error_detected <= 1'b0;
            total_errors <= 8'b0;
            corrected_errors <= 8'b0;
        end 
        else begin
            // Stage 1: Syndrome calculation and input registration
            code_stage1 <= code_in;
            syndrome_stage1[0] <= code_in[0] ^ code_in[2] ^ code_in[4] ^ code_in[6];
            syndrome_stage1[1] <= code_in[1] ^ code_in[2] ^ code_in[5] ^ code_in[6];
            syndrome_stage1[2] <= code_in[3] ^ code_in[4] ^ code_in[5] ^ code_in[6];
            
            // Stage 2: Error detection and data extraction
            syndrome_stage2 <= syndrome_stage1;
            data_stage2 <= {code_stage1[6], code_stage1[5], code_stage1[4], code_stage1[2]};
            error_detected_stage2 <= |syndrome_stage1;
            
            // Stage 3: Prepare for counter updates
            error_detected_stage3 <= error_detected_stage2;
            syndrome_stage3 <= syndrome_stage2;
            
            // Output stage: Update output and counters
            data_out <= data_stage2;
            error_detected <= error_detected_stage2;
            
            // Counter logic
            if (error_detected_stage3) 
                total_errors <= total_errors + 1;
            
            if (error_detected_stage3 && syndrome_stage3 != 3'b0) 
                corrected_errors <= corrected_errors + 1;
        end
    end
endmodule