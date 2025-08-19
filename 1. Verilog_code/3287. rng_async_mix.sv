module rng_async_mix_7(
    input      [7:0] in_cnt,
    output     [7:0] out_rand
);
    assign out_rand = {in_cnt[3:0] ^ in_cnt[7:4],
                       (in_cnt[1:0] + in_cnt[3:2]) ^ in_cnt[5:4]};
endmodule