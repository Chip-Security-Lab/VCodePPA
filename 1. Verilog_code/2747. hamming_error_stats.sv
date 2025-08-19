module hamming_error_stats(
    input clk, rst,
    input [6:0] code_in,
    output reg [3:0] data_out,
    output reg error_detected,
    output reg [7:0] total_errors,
    output reg [7:0] corrected_errors
);
    reg [2:0] syndrome;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_out <= 4'b0;
            error_detected <= 1'b0;
            syndrome <= 3'b0;
            total_errors <= 8'b0;
            corrected_errors <= 8'b0;
        end else begin
            syndrome[0] <= code_in[0] ^ code_in[2] ^ code_in[4] ^ code_in[6];
            syndrome[1] <= code_in[1] ^ code_in[2] ^ code_in[5] ^ code_in[6];
            syndrome[2] <= code_in[3] ^ code_in[4] ^ code_in[5] ^ code_in[6];
            
            error_detected <= |syndrome;
            if (|syndrome) total_errors <= total_errors + 1;
            if (|syndrome && syndrome != 3'b0) corrected_errors <= corrected_errors + 1;
            
            data_out <= {code_in[6], code_in[5], code_in[4], code_in[2]};
        end
    end
endmodule