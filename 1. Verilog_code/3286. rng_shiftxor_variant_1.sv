//SystemVerilog
module rng_shiftxor_6(
    input             clk,
    input             rst,
    input             en,
    output reg [7:0]  rnd
);
    reg [7:0] lfsr_reg;
    wire mix_high, mix_low, mix;

    // Balanced XOR tree for tmp_reg[7:4]
    wire x1 = lfsr_reg[7] ^ lfsr_reg[6];
    wire x2 = lfsr_reg[5] ^ lfsr_reg[4];
    assign mix = x1 ^ x2;

    always @(posedge clk) begin
        if (rst) begin
            lfsr_reg <= 8'hF0;
        end else if (en) begin
            lfsr_reg <= {lfsr_reg[6:0], mix};
        end
    end

    always @(*) begin
        rnd = lfsr_reg;
    end
endmodule