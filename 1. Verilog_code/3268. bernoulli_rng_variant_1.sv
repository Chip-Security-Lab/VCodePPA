//SystemVerilog
module bernoulli_rng #(
    parameter THRESHOLD = 128 // Probability = THRESHOLD/256
)(
    input wire clk,
    input wire rst,
    output wire random_bit
);
    reg [7:0] lfsr;
    reg random_bit_reg;

    always @(posedge clk) begin
        if (rst)
            lfsr <= 8'h1;
        else
            lfsr <= {lfsr[6:0], lfsr[7] ^ lfsr[5] ^ lfsr[4] ^ lfsr[3]};
    end

    always @(*) begin
        case (lfsr < THRESHOLD)
            1'b1: random_bit_reg = 1'b1;
            1'b0: random_bit_reg = 1'b0;
            default: random_bit_reg = 1'b0;
        endcase
    end

    assign random_bit = random_bit_reg;
endmodule