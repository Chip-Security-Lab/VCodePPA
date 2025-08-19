module diff_clk_buffer (
    input wire single_ended_clk,
    output wire clk_p,
    output wire clk_n
);
    // 直接反转信号生成差分时钟
    assign clk_p = single_ended_clk;
    assign clk_n = ~single_ended_clk;
endmodule