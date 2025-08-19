module rng_xorshift_18(
    input             clk,
    input             rst,
    input             en,
    output reg [7:0]  data_o
);
    reg [7:0] x = 8'hAA;
    always @(posedge clk) begin
        if(rst) x <= 8'hAA;
        else if(en) begin
            x = x ^ (x << 3);
            x = x ^ (x >> 2);
            x = x ^ (x << 1);
        end
        data_o <= x;
    end
endmodule