module rng_combine_14(
    input             clk,
    input             rst,
    input             en,
    output reg [7:0]  rnd
);
    wire [7:0] mix = (rnd << 3) ^ (rnd >> 2) ^ 8'h5A;
    always @(posedge clk) begin
        if(rst)   rnd <= 8'h99;
        else if(en) rnd <= mix;
    end
endmodule