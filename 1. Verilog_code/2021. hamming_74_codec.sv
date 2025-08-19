module hamming_74_codec (
    input clk, rst_n, encode_en,
    input [3:0] data_in,
    output reg [6:0] code_word,
    output reg error_flag
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) {code_word, error_flag} <= 0;
        else if (encode_en) begin
            code_word[6:4] <= data_in[3:1];
            code_word[3]   <= ^{data_in[3:1], data_in[0]};
            code_word[2]   <= ^{data_in[3], data_in[1], data_in[0]};
            code_word[1]   <= ^{data_in[3:2], data_in[0]};
            code_word[0]   <= ^{data_in};
        end
    end
endmodule