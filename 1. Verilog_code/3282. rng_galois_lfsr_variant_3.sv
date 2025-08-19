//SystemVerilog
// SystemVerilog
module rng_galois_lfsr_2(
    input             clk,
    input             rst_n,
    input             enable,
    output [15:0]     data_out
);

    reg  [15:0] state_reg;
    reg  [15:0] next_state_comb;

    //==============================================
    // Combinational logic: LFSR next state compute
    //==============================================
    always @* begin
        next_state_comb[0]  = state_reg[15];
        next_state_comb[1]  = state_reg[0] ^ state_reg[15];
        next_state_comb[2]  = state_reg[1];
        next_state_comb[3]  = state_reg[2] ^ state_reg[15];
        next_state_comb[15:4] = state_reg[14:3];
    end

    //==============================================
    // Sequential logic: State register update
    //==============================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state_reg <= 16'hACE1;
        else if (enable)
            state_reg <= next_state_comb;
    end

    //==============================================
    // Output logic: Drive data_out from state_reg
    //==============================================
    assign data_out = state_reg;

endmodule