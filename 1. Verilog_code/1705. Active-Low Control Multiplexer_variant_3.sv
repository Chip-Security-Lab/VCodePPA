//SystemVerilog
module active_low_mux(
    input [23:0] src_a, src_b,
    input sel_n, en_n,
    output [23:0] dest
);

    wire [23:0] mux_out;
    
    mux_selector selector(
        .src_a(src_a),
        .src_b(src_b),
        .sel_n(sel_n),
        .mux_out(mux_out)
    );
    
    enable_control enable(
        .mux_in(mux_out),
        .en_n(en_n),
        .dest(dest)
    );

endmodule

module mux_selector(
    input [23:0] src_a, src_b,
    input sel_n,
    output [23:0] mux_out
);
    assign mux_out = sel_n ? src_b : src_a;
endmodule

module enable_control(
    input [23:0] mux_in,
    input en_n,
    output [23:0] dest
);
    assign dest = en_n ? 24'b0 : mux_in;
endmodule