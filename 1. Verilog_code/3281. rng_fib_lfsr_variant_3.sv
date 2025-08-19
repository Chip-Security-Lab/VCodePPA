//SystemVerilog
module rng_fib_lfsr_1(
    input             clk,
    input             rst,
    input             en,
    output reg [7:0]  rand_out
);
    reg [7:0] lfsr_reg;
    reg [7:0] lfsr_reg_q;

    wire      tap_b7, tap_b5, tap_b3, tap_b2;
    wire      feedback_1, feedback_2;
    wire      feedback_bit;
    wire [7:0] next_lfsr;

    // Tap extraction for path balancing
    assign tap_b7 = lfsr_reg[7];
    assign tap_b5 = lfsr_reg[5];
    assign tap_b3 = lfsr_reg[3];
    assign tap_b2 = lfsr_reg[2];

    // Balanced XOR tree for feedback calculation
    assign feedback_1 = tap_b7 ^ tap_b5;
    assign feedback_2 = tap_b3 ^ tap_b2;
    assign feedback_bit = feedback_1 ^ feedback_2;

    assign next_lfsr = {lfsr_reg[6:0], feedback_bit};

    always @(posedge clk) begin
        if (rst) begin
            lfsr_reg <= 8'hA5;
        end else if (en) begin
            lfsr_reg <= next_lfsr;
        end
    end

    // Move output register behind the LFSR register update
    always @(posedge clk) begin
        if (rst) begin
            lfsr_reg_q <= 8'hA5;
        end else if (en) begin
            lfsr_reg_q <= next_lfsr;
        end
    end

    always @(*) begin
        rand_out = lfsr_reg_q;
    end
endmodule