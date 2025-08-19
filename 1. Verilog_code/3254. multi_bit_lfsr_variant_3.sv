//SystemVerilog
module multi_bit_lfsr (
    input  clk,
    input  rst,
    output [19:0] rnd_out
);
    wire  [3:0]  taps_comb_out;
    reg   [3:0]  taps_pipe_reg;
    reg   [19:0] lfsr_reg;
    reg   [19:0] lfsr_next_pipe_reg;
    wire  [19:0] lfsr_next_comb;

    // Combinational logic for taps calculation
    lfsr_tap_logic u_lfsr_tap_logic (
        .lfsr_state(lfsr_reg),
        .taps_out(taps_comb_out)
    );

    // Pipeline register for taps
    always @(posedge clk) begin
        if (rst)
            taps_pipe_reg <= 4'hF;
        else
            taps_pipe_reg <= taps_comb_out;
    end

    // Combinational logic for next LFSR value (using pipeline tap)
    assign lfsr_next_comb = {lfsr_reg[15:0], taps_pipe_reg};

    // Pipeline register for lfsr_next_comb
    always @(posedge clk) begin
        if (rst)
            lfsr_next_pipe_reg <= 20'hFACEB;
        else
            lfsr_next_pipe_reg <= lfsr_next_comb;
    end

    // Sequential logic for LFSR state update
    always @(posedge clk) begin
        if (rst)
            lfsr_reg <= 20'hFACEB;
        else
            lfsr_reg <= lfsr_next_pipe_reg;
    end

    assign rnd_out = lfsr_reg;
endmodule

module lfsr_tap_logic (
    input  [19:0] lfsr_state,
    output [3:0]  taps_out
);
    assign taps_out[0] = lfsr_state[19] ^ lfsr_state[16];
    assign taps_out[1] = lfsr_state[15] ^ lfsr_state[12];
    assign taps_out[2] = lfsr_state[11] ^ lfsr_state[8];
    assign taps_out[3] = lfsr_state[7]  ^ lfsr_state[0];
endmodule