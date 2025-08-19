module active_low_mux(
    input [23:0] src_a, src_b,
    input sel_n, en_n,
    output [23:0] dest
);
    assign dest = (!en_n) ? ((!sel_n) ? src_a : src_b) : 24'h0;
endmodule