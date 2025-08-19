//SystemVerilog
module rng_galois_lfsr_2(
    input             clk,
    input             rst_n,
    input             enable,
    output reg [15:0] data_out
);
    reg [15:0] state;
    wire       lfsr_update;
    wire [15:0] next_state;

    assign lfsr_update = rst_n & enable;

    // Optimized LFSR next state computation
    assign next_state = {
        state[14:3],                                // state[15:4]
        state[2] ^ state[15],                       // state[3]
        state[1],                                   // state[2]
        state[0] ^ state[15],                       // state[1]
        state[15]                                   // state[0]
    };

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= 16'hACE1;
        else if (enable)
            state <= next_state;
    end

    always @(*) data_out = state;
endmodule