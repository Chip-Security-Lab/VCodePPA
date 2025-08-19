//SystemVerilog
// Top-level module: ASCII to Binary Decoder (Pipelined Hierarchical Structure)
module ascii_dec_to_bin(
    input         clk,
    input         rst_n,
    input  [7:0]  ascii_char_in,
    output [3:0]  binary_out,
    output        valid
);

    // Pipeline registers and combinational signals
    reg  [7:0]  ascii_char_stage1;
    reg         is_decimal_digit_stage2_reg;
    reg  [3:0]  bin_value_stage2_reg;

    wire        is_decimal_digit_stage2;
    wire [3:0]  bin_value_stage2;

    // Stage 2: Range Check and Value Extraction (combinational)
    ascii_decoder_stage2 u_stage2 (
        .ascii_char_in         (ascii_char_stage1),
        .is_decimal_digit_out  (is_decimal_digit_stage2),
        .bin_value_out         (bin_value_stage2)
    );

    // Merged pipeline registers: Stage 1 and Stage 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ascii_char_stage1           <= 8'd0;
            is_decimal_digit_stage2_reg <= 1'b0;
            bin_value_stage2_reg        <= 4'd0;
        end else begin
            ascii_char_stage1           <= ascii_char_in;
            is_decimal_digit_stage2_reg <= is_decimal_digit_stage2;
            bin_value_stage2_reg        <= bin_value_stage2;
        end
    end

    // Stage 3: Output Assignment
    assign binary_out = is_decimal_digit_stage2_reg ? bin_value_stage2_reg : 4'b0000;
    assign valid      = is_decimal_digit_stage2_reg;

endmodule

// Stage 2 Submodule: Range Check and Binary Conversion
module ascii_decoder_stage2(
    input  [7:0] ascii_char_in,
    output       is_decimal_digit_out,
    output [3:0] bin_value_out
);
    wire in_range;
    wire [3:0] binary_value;

    assign in_range     = (ascii_char_in >= 8'h30) && (ascii_char_in <= 8'h39);
    assign binary_value = ascii_char_in - 8'h30;

    assign is_decimal_digit_out = in_range;
    assign bin_value_out        = binary_value;
endmodule