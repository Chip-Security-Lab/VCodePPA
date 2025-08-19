module manchester_decoder (
    input encoded,
    output reg decoded,
    output reg clk_recovered
);
    reg prev_bit;
    always @(*) begin
        decoded = (encoded ^ prev_bit);
        clk_recovered = (encoded != prev_bit);
        prev_bit = encoded;
    end
endmodule