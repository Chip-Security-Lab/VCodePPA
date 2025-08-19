//SystemVerilog
module triangular_dist_rng (
    input wire clock,
    input wire reset,
    output wire [7:0] random_num
);

// Stage 1: Combined LFSR Generation and Addition
reg [7:0] lfsr1_stage1, lfsr2_stage1;
reg [8:0] sum_stage1;

always @(posedge clock) begin
    if (reset) begin
        lfsr1_stage1 <= 8'h01;
        lfsr2_stage1 <= 8'hFF;
        sum_stage1   <= 9'd0;
    end else begin
        lfsr1_stage1 <= {lfsr1_stage1[6:0], lfsr1_stage1[7] ^ lfsr1_stage1[5] ^ lfsr1_stage1[4] ^ lfsr1_stage1[3]};
        lfsr2_stage1 <= {lfsr2_stage1[6:0], lfsr2_stage1[7] ^ lfsr2_stage1[6] ^ lfsr2_stage1[5] ^ lfsr2_stage1[0]};
        sum_stage1   <= lfsr1_stage1 + lfsr2_stage1;
    end
end

// Stage 2: Output register for final triangular random number
reg [7:0] random_num_stage2;

always @(posedge clock) begin
    if (reset) begin
        random_num_stage2 <= 8'd0;
    end else begin
        random_num_stage2 <= sum_stage1[8:1]; // Equivalent to (lfsr1+lfsr2)>>1
    end
end

assign random_num = random_num_stage2;

endmodule