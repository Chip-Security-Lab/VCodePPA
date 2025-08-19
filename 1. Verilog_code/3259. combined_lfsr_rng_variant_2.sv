//SystemVerilog
module combined_lfsr_rng (
    input wire clk,
    input wire n_rst,
    output wire [31:0] random_value
);
    reg [16:0] lfsr1;
    reg [18:0] lfsr2;
    wire feedback1;
    wire feedback2;

    // Intermediate signals for feedback1
    wire lfsr1_bit16;
    wire lfsr1_bit13;
    wire lfsr1_xor;

    assign lfsr1_bit16 = lfsr1[16];
    assign lfsr1_bit13 = lfsr1[13];

    assign lfsr1_xor = lfsr1_bit16 ^ lfsr1_bit13;
    assign feedback1 = lfsr1_xor;

    // Intermediate signals for feedback2
    wire lfsr2_bit18;
    wire lfsr2_bit17;
    wire lfsr2_bit11;
    wire lfsr2_bit0;
    wire xor1;
    wire xor2;
    wire xor_final;

    assign lfsr2_bit18 = lfsr2[18];
    assign lfsr2_bit17 = lfsr2[17];
    assign lfsr2_bit11 = lfsr2[11];
    assign lfsr2_bit0  = lfsr2[0];

    assign xor1 = lfsr2_bit18 ^ lfsr2_bit17;
    assign xor2 = lfsr2_bit11 ^ lfsr2_bit0;
    assign xor_final = xor1 ^ xor2;
    assign feedback2 = xor_final;

    always @(posedge clk or negedge n_rst) begin
        if (!n_rst) begin
            lfsr1 <= 17'h1ACEF;
            lfsr2 <= 19'h5B4FC;
        end else begin
            lfsr1 <= {lfsr1[15:0], feedback1};
            lfsr2 <= {lfsr2[17:0], feedback2};
        end
    end

    assign random_value = {lfsr1[15:0], lfsr2[15:0]};
endmodule