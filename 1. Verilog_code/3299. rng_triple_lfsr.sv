module rng_triple_lfsr_19(
    input            clk,
    input            rst,
    input            en,
    output reg [7:0] rnd
);
    reg [7:0] a=8'hFE, b=8'hBD, c=8'h73;
    wire fA = a[7] ^ a[3], fB = b[7] ^ b[2], fC = c[7] ^ c[1];
    always @(posedge clk) begin
        if(rst) begin
            a<=8'hFE; b<=8'hBD; c<=8'h73; rnd<=0;
        end else if(en) begin
            a <= {a[6:0], fA};
            b <= {b[6:0], fB};
            c <= {c[6:0], fC};
            rnd <= a ^ b ^ c;
        end
    end
endmodule