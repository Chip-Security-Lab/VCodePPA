module wave15_ring_osc(
    output wire ring_out
);
    wire n1, n2, n3;
    assign #1 n1 = ~n3;
    assign #1 n2 = ~n1;
    assign #1 n3 = ~n2;
    assign ring_out = n3;
endmodule
