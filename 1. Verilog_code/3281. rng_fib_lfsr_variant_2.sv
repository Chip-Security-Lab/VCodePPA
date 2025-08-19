//SystemVerilog
module rng_fib_lfsr_1(
    input             clk,
    input             rst,
    input             en,
    output reg [7:0]  rand_out
);
    reg [7:0] lfsr_reg;
    // Simplified feedback_bit using Boolean algebra:
    // feedback_bit = ^(lfsr_reg & 8'b10110100)
    // 8'b10110100: bits 7,5,4,2
    // feedback_bit = lfsr_reg[7] ^ lfsr_reg[5] ^ lfsr_reg[4] ^ lfsr_reg[2]
    wire feedback_bit = lfsr_reg[7] ^ lfsr_reg[5] ^ lfsr_reg[4] ^ lfsr_reg[2];

    reg  [7:0] karatsuba_a;
    reg  [7:0] karatsuba_b;
    wire [15:0] karatsuba_product;

    always @(posedge clk) begin
        if(rst) begin
            lfsr_reg    <= 8'hA5;
            karatsuba_a <= 8'd0;
            karatsuba_b <= 8'd0;
        end else if(en) begin
            lfsr_reg    <= {lfsr_reg[6:0], feedback_bit};
            karatsuba_a <= {lfsr_reg[6:0], feedback_bit};
            karatsuba_b <= 8'h1B;
        end
    end

    wire [7:0] karatsuba_rand;
    assign karatsuba_rand = karatsuba_product[7:0];

    always @(*) begin
        rand_out = karatsuba_rand;
    end

    karatsuba_mult8 u_karatsuba_mult8 (
        .a(karatsuba_a),
        .b(karatsuba_b),
        .product(karatsuba_product)
    );
endmodule

module karatsuba_mult8 (
    input  [7:0] a,
    input  [7:0] b,
    output [15:0] product
);
    wire [3:0] a_hi = a[7:4];
    wire [3:0] a_lo = a[3:0];
    wire [3:0] b_hi = b[7:4];
    wire [3:0] b_lo = b[3:0];

    wire [7:0] z0;
    wire [7:0] z2;
    wire [7:0] z1;
    // a_sum = a_hi ^ a_lo, b_sum = b_hi ^ b_lo
    wire [3:0] a_sum = a_hi ^ a_lo;
    wire [3:0] b_sum = b_hi ^ b_lo;

    assign z0 = a_lo * b_lo;
    assign z2 = a_hi * b_hi;
    // z1 = (a_sum * b_sum) ^ z0 ^ z2
    assign z1 = (a_sum * b_sum) ^ z0 ^ z2;

    // product = {z2, 8'b0} ^ {z1, 4'b0} ^ z0
    // Use Boolean algebra: XOR and concatenation are minimal for this logic
    assign product = {z2, 8'b0} ^ {z1, 4'b0} ^ z0;
endmodule