//SystemVerilog
module hamming_74_codec (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        encode_en,
    input  wire [3:0]  data_in,
    output reg  [6:0]  code_word,
    output reg         error_flag
);
    // Intermediate variables for code word bits
    wire parity_bit_3;
    wire parity_bit_2;
    wire parity_bit_1;
    wire parity_bit_0;
    wire [2:0] data_bits_high;
    wire       encode_en_active;
    wire       rst_n_active;
    wire [6:0] next_code_word;
    wire       next_error_flag;

    // Decompose conditions for better PPA and clarity
    assign rst_n_active = rst_n;
    assign encode_en_active = encode_en;

    assign data_bits_high = data_in[3:1];

    assign parity_bit_3 = data_in[3] ^ data_in[2] ^ data_in[1] ^ data_in[0];
    assign parity_bit_2 = data_in[3] ^ data_in[1] ^ data_in[0];
    assign parity_bit_1 = data_in[3] ^ data_in[2] ^ data_in[0];
    assign parity_bit_0 = data_in[3] ^ data_in[2] ^ data_in[1] ^ data_in[0];

    assign next_code_word[6:4] = data_bits_high;
    assign next_code_word[3]   = parity_bit_3;
    assign next_code_word[2]   = parity_bit_2;
    assign next_code_word[1]   = parity_bit_1;
    assign next_code_word[0]   = parity_bit_0;

    assign next_error_flag = 1'b0;

    always @(posedge clk or negedge rst_n_active) begin
        if (!rst_n_active) begin
            code_word  <= 7'b0000000;
            error_flag <= 1'b0;
        end else begin
            if (encode_en_active) begin
                code_word  <= next_code_word;
                error_flag <= next_error_flag;
            end
        end
    end
endmodule