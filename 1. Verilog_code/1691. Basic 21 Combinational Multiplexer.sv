module basic_mux_2to1(
    input [7:0] data0, data1,
    input sel,
    output [7:0] out
);
    assign out = sel ? data1 : data0;
endmodule