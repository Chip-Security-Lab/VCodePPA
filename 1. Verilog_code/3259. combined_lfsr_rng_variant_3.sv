//SystemVerilog
module combined_lfsr_rng (
    input wire clk,
    input wire n_rst,
    output wire [31:0] random_value
);
    reg [16:0] lfsr1;
    reg [18:0] lfsr2;

    // Intermediate signals for feedback calculation
    wire lfsr1_bit16, lfsr1_bit13;
    wire lfsr2_bit18, lfsr2_bit17, lfsr2_bit11, lfsr2_bit0;
    wire feedback1, feedback2;

    assign lfsr1_bit16 = lfsr1[16];
    assign lfsr1_bit13 = lfsr1[13];
    assign feedback1 = lfsr1_bit16 ^ lfsr1_bit13;

    assign lfsr2_bit18 = lfsr2[18];
    assign lfsr2_bit17 = lfsr2[17];
    assign lfsr2_bit11 = lfsr2[11];
    assign lfsr2_bit0  = lfsr2[0];
    assign feedback2 = lfsr2_bit18 ^ lfsr2_bit17 ^ lfsr2_bit11 ^ lfsr2_bit0;

    // Intermediate signals for reset and update
    wire reset_active;
    assign reset_active = ~n_rst;

    always @(posedge clk) begin
        if (reset_active) begin
            lfsr1 <= 17'h1ACEF;
            lfsr2 <= 19'h5B4FC;
        end else begin
            // Next state intermediate signals
            reg [16:0] next_lfsr1;
            reg [18:0] next_lfsr2;
            next_lfsr1 = {lfsr1[15:0], feedback1};
            next_lfsr2 = {lfsr2[17:0], feedback2};
            lfsr1 <= next_lfsr1;
            lfsr2 <= next_lfsr2;
        end
    end

    // Output: Concatenate the lower 16 bits of both LFSRs for a 32-bit output
    wire [15:0] lfsr1_lower16, lfsr2_lower16;
    assign lfsr1_lower16 = lfsr1[15:0];
    assign lfsr2_lower16 = lfsr2[15:0];
    assign random_value = {lfsr1_lower16, lfsr2_lower16};
endmodule