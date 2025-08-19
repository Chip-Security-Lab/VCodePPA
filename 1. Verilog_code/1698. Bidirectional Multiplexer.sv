module bidir_mux(
    inout [7:0] port_a, port_b,
    input direction,
    input enable
);
    assign port_a = (enable && !direction) ? port_b : 8'bz;
    assign port_b = (enable && direction) ? port_a : 8'bz;
endmodule