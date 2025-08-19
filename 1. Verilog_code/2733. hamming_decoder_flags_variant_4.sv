//SystemVerilog
module hamming_decoder_flags(
    input clk, rst_n,
    input [11:0] code_word,
    output reg [7:0] data_out,
    output reg error_fixed, double_error
);
    // Buffered code_word signals
    reg [11:0] code_word_buf1, code_word_buf2;
    
    // Syndrome calculation registers
    reg [3:0] syndrome;
    
    // First level of buffering for high fanout code_word signal
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            code_word_buf1 <= 12'b0;
            code_word_buf2 <= 12'b0;
        end else begin
            code_word_buf1 <= code_word;
            code_word_buf2 <= code_word;
        end
    end
    
    // Syndrome calculation using buffered signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            syndrome <= 4'b0;
        end else begin
            syndrome[0] <= ^(code_word_buf1 & 12'b101010101010);
            syndrome[1] <= ^(code_word_buf1 & 12'b011001100110);
            syndrome[2] <= ^(code_word_buf1 & 12'b000111100000);
            syndrome[3] <= ^(code_word_buf1 & 12'b000000011110);
        end
    end
    
    // Buffered syndrome for high fanout signals
    reg [3:0] syndrome_buf;
    reg parity_check;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            syndrome_buf <= 4'b0;
            parity_check <= 1'b0;
        end else begin
            syndrome_buf <= syndrome;
            parity_check <= ^syndrome ^ code_word_buf2[11];
        end
    end
    
    // Output logic with buffered signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 8'b0;
            error_fixed <= 1'b0;
            double_error <= 1'b0;
        end else begin
            error_fixed <= |syndrome_buf && ~parity_check;
            double_error <= |syndrome_buf && parity_check;
            data_out <= {code_word_buf2[10:7], code_word_buf2[6:4], code_word_buf2[2]};
        end
    end
endmodule