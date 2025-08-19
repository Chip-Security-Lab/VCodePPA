module triangular_dist_rng (
    input wire clock,
    input wire reset,
    output wire [7:0] random_num
);
    reg [7:0] lfsr1, lfsr2;
    
    always @(posedge clock) begin
        if (reset) begin
            lfsr1 <= 8'h01;
            lfsr2 <= 8'hFF;
        end else begin
            lfsr1 <= {lfsr1[6:0], lfsr1[7] ^ lfsr1[5] ^ lfsr1[4] ^ lfsr1[3]};
            lfsr2 <= {lfsr2[6:0], lfsr2[7] ^ lfsr2[6] ^ lfsr2[5] ^ lfsr2[0]};
        end
    end
    
    // Triangular distribution by averaging two uniform distributions
    assign random_num = (lfsr1 + lfsr2) >> 1;
endmodule