module rng_hash_15(
    input             clk,
    input             rst_n,
    input             enable,
    output reg [7:0]  out_v
);
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)  out_v <= 8'hD2;
        else if(enable) out_v <= {out_v[6:0], ^(out_v & 8'hA3)};
    end
endmodule