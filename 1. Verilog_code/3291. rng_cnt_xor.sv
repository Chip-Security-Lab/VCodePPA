module rng_cnt_xor_11(
    input            clk,
    input            rst,
    input            en,
    output reg [7:0] rnd
);
    reg [7:0] cnt;
    always @(posedge clk) begin
        if(rst)     cnt <= 0;
        else if(en) cnt <= cnt + 1;
        rnd <= cnt ^ {cnt[3:0], cnt[7:4]};
    end
endmodule