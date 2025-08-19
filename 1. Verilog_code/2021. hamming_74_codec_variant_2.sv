//SystemVerilog
// Top-level module: Hamming(7,4) Codec
module hamming_74_codec (
    input        clk,
    input        rst_n,
    input        encode_en,
    input  [3:0] data_in,
    output [6:0] code_word,
    output       error_flag
);

    reg  [6:0] code_word_reg;
    reg        error_flag_reg;
    wire [6:0] code_word_enc;

    // Hamming(7,4) Encoder logic
    hamming_74_encoder u_encoder (
        .data_in   (data_in),
        .encode_en (encode_en),
        .code_word (code_word_enc)
    );

    // Synchronous output register logic (merged)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            code_word_reg  <= 7'b0;
            error_flag_reg <= 1'b0;
        end else if (encode_en) begin
            code_word_reg  <= code_word_enc;
            error_flag_reg <= 1'b0;
        end
    end

    assign code_word  = code_word_reg;
    assign error_flag = error_flag_reg;

endmodule

// -----------------------------------------------------------------------------
// Submodule: Hamming(7,4) Encoder
// Function: Generates the (7,4) Hamming codeword from 4-bit input data
// -----------------------------------------------------------------------------
module hamming_74_encoder (
    input  [3:0] data_in,
    input        encode_en,
    output [6:0] code_word
);
    reg [6:0] code_word_int;
    always @(*) begin
        if (encode_en) begin
            code_word_int[6:4] = data_in[3:1];
            code_word_int[3]   = ^{data_in[3:1], data_in[0]};
            code_word_int[2]   = ^{data_in[3], data_in[1], data_in[0]};
            code_word_int[1]   = ^{data_in[3:2], data_in[0]};
            code_word_int[0]   = ^{data_in};
        end else begin
            code_word_int = 7'b0;
        end
    end
    assign code_word = code_word_int;
endmodule