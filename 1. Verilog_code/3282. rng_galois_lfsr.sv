module rng_galois_lfsr_2(
    input             clk,
    input             rst_n,
    input             enable,
    output reg [15:0] data_out
);
    reg [15:0] state;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)  state <= 16'hACE1;
        else if(enable) begin
            state[0]  <= state[15];
            state[1]  <= state[0]  ^ state[15];
            state[2]  <= state[1];
            state[3]  <= state[2]  ^ state[15];
            state[15:4] <= state[14:3];
        end
    end
    always @(*) data_out = state;
endmodule