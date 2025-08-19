//SystemVerilog
module leading_zero #(parameter DW=8) (
    input  wire [DW-1:0] data,
    output reg  [$clog2(DW+1)-1:0] leading_zero_count
);
    integer bit_index;
    reg [DW-1:0] data_inverted;
    reg [DW-1:0] one_complement;
    reg [DW-1:0] two_complement;
    reg subtractor_carry;

    always @* begin
        // Binary Two's Complement Subtraction to compute (0 - data)
        data_inverted = ~data; // one's complement
        one_complement = data_inverted;
        {subtractor_carry, two_complement} = {1'b0, one_complement} + {{(DW){1'b0}}, 1'b1}; // add 1 for two's complement

        leading_zero_count = DW;
        bit_index = DW - 1;
        while (bit_index >= 0) begin
            if (data[bit_index]) leading_zero_count = DW - 1 - bit_index;
            bit_index = bit_index - 1;
        end
    end
endmodule