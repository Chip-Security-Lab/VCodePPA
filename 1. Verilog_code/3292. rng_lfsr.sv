module rng_lfsr_12(
    input           clk,
    input           en,
    output [3:0]    rand_out
);
    reg [3:0] state = 4'b1010;
    wire fb = state[3] ^ state[2];
    always @(posedge clk) if(en) state <= {state[2:0], fb};
    assign rand_out = state;
endmodule