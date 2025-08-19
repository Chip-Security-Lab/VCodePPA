module rng_cross_10(
    input             clk,
    input             rst,
    input             en,
    output reg [7:0]  out_rnd
);
    reg [7:0] s1, s2;
    always @(posedge clk) begin
        if(rst) begin
            s1 <= 8'hF0; s2 <= 8'h0F;
        end else if(en) begin
            s1 <= {s1[6:0], s2[7] ^ s1[0]};
            s2 <= {s2[6:0], s1[7] ^ s2[0]};
        end
    end
    always @(*) out_rnd = s1 ^ s2;
endmodule