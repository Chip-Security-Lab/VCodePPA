//SystemVerilog
module hamming_error_stats(
    input clk, rst,
    input [6:0] code_in,
    output reg [3:0] data_out,
    output reg error_detected,
    output reg [7:0] total_errors,
    output reg [7:0] corrected_errors
);
    // Buffer registers for high fan-out signals
    reg [6:0] code_in_buf1, code_in_buf2;
    reg [2:0] syndrome;
    reg [2:0] syndrome_buf;
    reg b0; // Intermediate signal for syndrome calculation
    reg b0_buf1, b0_buf2;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            code_in_buf1 <= 7'b0;
            code_in_buf2 <= 7'b0;
            syndrome <= 3'b0;
            syndrome_buf <= 3'b0;
            b0 <= 1'b0;
            b0_buf1 <= 1'b0;
            b0_buf2 <= 1'b0;
            data_out <= 4'b0;
            error_detected <= 1'b0;
            total_errors <= 8'b0;
            corrected_errors <= 8'b0;
        end else begin
            // Buffer high fan-out input signals
            code_in_buf1 <= code_in;
            code_in_buf2 <= code_in;
            
            // Calculate syndrome using buffered signals
            syndrome[0] <= code_in_buf1[0] ^ code_in_buf1[2] ^ code_in_buf1[4] ^ code_in_buf1[6];
            syndrome[1] <= code_in_buf1[1] ^ code_in_buf1[2] ^ code_in_buf1[5] ^ code_in_buf1[6];
            syndrome[2] <= code_in_buf2[3] ^ code_in_buf2[4] ^ code_in_buf2[5] ^ code_in_buf2[6];
            
            // Buffer syndrome for multiple uses
            syndrome_buf <= syndrome;
            
            // Create intermediate signal for OR operation and buffer it
            b0 <= |syndrome;
            b0_buf1 <= b0;
            b0_buf2 <= b0;
            
            error_detected <= b0_buf1;
            
            // Use buffered signals for conditional operations
            if (b0_buf1) total_errors <= total_errors + 1;
            if (b0_buf2 && syndrome_buf != 3'b0) corrected_errors <= corrected_errors + 1;
            
            // Output data using buffered input
            data_out <= {code_in_buf2[6], code_in_buf2[5], code_in_buf2[4], code_in_buf2[2]};
        end
    end
endmodule