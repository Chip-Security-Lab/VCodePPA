//SystemVerilog
module hamming_error_stats(
    input clk, rst,
    input [6:0] code_in,
    output reg [3:0] data_out,
    output reg error_detected,
    output reg [7:0] total_errors,
    output reg [7:0] corrected_errors
);
    // Stage 1 registers - compute syndrome
    reg [6:0] code_stage1;
    reg [2:0] syndrome_stage1;
    
    // Stage 2 registers - error detection
    reg [2:0] syndrome_stage2;
    reg error_detected_stage2;
    reg [6:0] code_stage2;
    
    // Stage 3 registers - counter logic
    reg [7:0] total_errors_next;
    reg [7:0] corrected_errors_next;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset stage 1
            code_stage1 <= 7'b0;
            syndrome_stage1 <= 3'b0;
            
            // Reset stage 2
            syndrome_stage2 <= 3'b0;
            error_detected_stage2 <= 1'b0;
            code_stage2 <= 7'b0;
            
            // Reset outputs
            data_out <= 4'b0;
            error_detected <= 1'b0;
            total_errors <= 8'b0;
            corrected_errors <= 8'b0;
            
            // Reset intermediate
            total_errors_next <= 8'b0;
            corrected_errors_next <= 8'b0;
        end else begin
            // Stage 1: Register inputs and compute syndrome
            code_stage1 <= code_in;
            syndrome_stage1[0] <= code_in[0] ^ code_in[2] ^ code_in[4] ^ code_in[6];
            syndrome_stage1[1] <= code_in[1] ^ code_in[2] ^ code_in[5] ^ code_in[6];
            syndrome_stage1[2] <= code_in[3] ^ code_in[4] ^ code_in[5] ^ code_in[6];
            
            // Stage 2: Error detection and prepare counters
            syndrome_stage2 <= syndrome_stage1;
            error_detected_stage2 <= |syndrome_stage1;
            code_stage2 <= code_stage1;
            
            // Prepare next counter values
            total_errors_next <= total_errors + (|syndrome_stage2 ? 1'b1 : 1'b0);
            corrected_errors_next <= corrected_errors + ((|syndrome_stage2 && syndrome_stage2 != 3'b0) ? 1'b1 : 1'b0);
            
            // Stage 3: Final outputs
            data_out <= {code_stage2[6], code_stage2[5], code_stage2[4], code_stage2[2]};
            error_detected <= error_detected_stage2;
            total_errors <= total_errors_next;
            corrected_errors <= corrected_errors_next;
        end
    end
endmodule