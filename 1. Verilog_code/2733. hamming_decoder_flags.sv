module hamming_decoder_flags(
    input clk, rst_n,
    input [11:0] code_word,
    output reg [7:0] data_out,
    output reg error_fixed, double_error
);
    reg [3:0] syndrome;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 8'b0; error_fixed <= 1'b0; double_error <= 1'b0;
        end else begin
            syndrome[0] <= code_word[0] ^ code_word[2] ^ code_word[4] ^ code_word[6] ^ code_word[8] ^ code_word[10];
            syndrome[1] <= code_word[1] ^ code_word[2] ^ code_word[5] ^ code_word[6] ^ code_word[9] ^ code_word[10];
            syndrome[2] <= code_word[3] ^ code_word[4] ^ code_word[5] ^ code_word[6];
            syndrome[3] <= code_word[7] ^ code_word[8] ^ code_word[9] ^ code_word[10];
            
            error_fixed <= |syndrome && ~(^syndrome ^ code_word[11]);
            double_error <= |syndrome && (^syndrome ^ code_word[11]);
            data_out <= {code_word[10:7], code_word[6:4], code_word[2]};
        end
    end
endmodule