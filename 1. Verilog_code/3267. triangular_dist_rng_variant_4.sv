//SystemVerilog
module triangular_dist_rng (
    input wire clock,
    input wire reset,
    output wire [7:0] random_num
);

    reg [7:0] lfsr1_reg;
    reg [7:0] lfsr2_reg;
    reg [7:0] random_num_reg;

    // LFSR1 logic: Handles updating of lfsr1_reg
    // Polynomial: x^8 + x^6 + x^5 + x^4 + 1
    always @(posedge clock) begin
        if (reset)
            lfsr1_reg <= 8'h01;
        else
            lfsr1_reg <= {lfsr1_reg[6:0], lfsr1_reg[7] ^ lfsr1_reg[5] ^ lfsr1_reg[4] ^ lfsr1_reg[3]};
    end

    // LFSR2 logic: Handles updating of lfsr2_reg
    // Polynomial: x^8 + x^7 + x^6 + x^1 + 1
    always @(posedge clock) begin
        if (reset)
            lfsr2_reg <= 8'hFF;
        else
            lfsr2_reg <= {lfsr2_reg[6:0], lfsr2_reg[7] ^ lfsr2_reg[6] ^ lfsr2_reg[5] ^ lfsr2_reg[0]};
    end

    // Random number calculation: Outputs the triangular distributed number
    always @(posedge clock) begin
        random_num_reg <= (lfsr1_reg + lfsr2_reg) >> 1;
    end

    assign random_num = random_num_reg;

endmodule