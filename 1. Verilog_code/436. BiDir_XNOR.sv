module BiDir_XNOR(
    inout [7:0] bus_a, bus_b,
    input dir,
    output [7:0] result
);
    assign bus_a = dir ? ~(bus_a ^ bus_b) : 8'hzz;
    assign bus_b = dir ? 8'hzz : ~(bus_a ^ bus_b);
    assign result = bus_a;
endmodule
