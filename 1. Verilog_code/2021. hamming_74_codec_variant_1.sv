//SystemVerilog
module hamming_74_codec (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        encode_en,
    input  wire [3:0]  data_in,
    output reg  [6:0]  code_word,
    output reg         error_flag
);

    // Stage 1: Input Latching
    reg [3:0] data_in_stage1;
    reg       encode_en_stage1;
    reg       valid_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_stage1   <= 4'b0;
            encode_en_stage1 <= 1'b0;
            valid_stage1     <= 1'b0;
        end else begin
            data_in_stage1   <= data_in;
            encode_en_stage1 <= encode_en;
            valid_stage1     <= encode_en;
        end
    end

    // Stage 2: Partial Parity Calculation
    reg [2:0] data_high_stage2;
    reg       data_bit0_stage2;
    reg       encode_en_stage2;
    reg       valid_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_high_stage2   <= 3'b0;
            data_bit0_stage2   <= 1'b0;
            encode_en_stage2   <= 1'b0;
            valid_stage2       <= 1'b0;
        end else begin
            data_high_stage2   <= data_in_stage1[3:1];
            data_bit0_stage2   <= data_in_stage1[0];
            encode_en_stage2   <= encode_en_stage1;
            valid_stage2       <= valid_stage1;
        end
    end

    // Stage 3: Parity Calculation
    reg [2:0] data_high_stage3;
    reg       data_bit0_stage3;
    reg       parity3_stage3;
    reg       parity2_stage3;
    reg       parity1_stage3;
    reg       parity0_stage3;
    reg       encode_en_stage3;
    reg       valid_stage3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_high_stage3   <= 3'b0;
            data_bit0_stage3   <= 1'b0;
            parity3_stage3     <= 1'b0;
            parity2_stage3     <= 1'b0;
            parity1_stage3     <= 1'b0;
            parity0_stage3     <= 1'b0;
            encode_en_stage3   <= 1'b0;
            valid_stage3       <= 1'b0;
        end else begin
            data_high_stage3   <= data_high_stage2;
            data_bit0_stage3   <= data_bit0_stage2;
            parity3_stage3     <= ^{data_high_stage2, data_bit0_stage2};
            parity2_stage3     <= ^{data_high_stage2[2], data_high_stage2[0], data_bit0_stage2};
            parity1_stage3     <= ^{data_high_stage2[2:1], data_bit0_stage2};
            parity0_stage3     <= ^{data_high_stage2, data_bit0_stage2};
            encode_en_stage3   <= encode_en_stage2;
            valid_stage3       <= valid_stage2;
        end
    end

    // Stage 4: Output Registering
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            code_word   <= 7'b0;
            error_flag  <= 1'b0;
        end else if (encode_en_stage3 && valid_stage3) begin
            code_word[6:4] <= data_high_stage3;
            code_word[3]   <= parity3_stage3;
            code_word[2]   <= parity2_stage3;
            code_word[1]   <= parity1_stage3;
            code_word[0]   <= parity0_stage3;
            error_flag     <= 1'b0;
        end else begin
            error_flag     <= 1'b0;
        end
    end

endmodule