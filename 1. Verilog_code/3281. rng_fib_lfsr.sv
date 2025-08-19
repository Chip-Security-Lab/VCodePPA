module rng_fib_lfsr_1(
    input             clk,
    input             rst,
    input             en,
    output reg [7:0]  rand_out
);
    reg [7:0] lfsr;
    wire      fb = ^(lfsr & 8'b10110100);
    always @(posedge clk) begin
        if(rst)    lfsr <= 8'hA5;
        else if(en)lfsr <= {lfsr[6:0], fb};
    end
    always @(*) rand_out = lfsr;
endmodule