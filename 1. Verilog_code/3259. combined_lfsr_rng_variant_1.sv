//SystemVerilog
module combined_lfsr_rng (
    input wire clk,
    input wire n_rst,
    output wire [31:0] random_value
);
    reg [16:0] lfsr1_reg;
    reg [18:0] lfsr2_reg;
    wire feedback1_opt, feedback2_opt;

    // Optimized feedback: use reduction XOR for feedback2, minimal logic for feedback1
    assign feedback1_opt = lfsr1_reg[16] ^ lfsr1_reg[13];
    assign feedback2_opt = lfsr2_reg[18] ^ lfsr2_reg[17] ^ lfsr2_reg[11] ^ lfsr2_reg[0];

    always @(posedge clk or negedge n_rst) begin
        if (!n_rst) begin
            lfsr1_reg <= 17'h1ACEF;
            lfsr2_reg <= 19'h5B4FC;
        end else begin
            lfsr1_reg <= {lfsr1_reg[15:0], feedback1_opt};
            lfsr2_reg <= {lfsr2_reg[17:0], feedback2_opt};
        end
    end

    assign random_value = {lfsr1_reg[15:0], lfsr2_reg[15:0]};
endmodule