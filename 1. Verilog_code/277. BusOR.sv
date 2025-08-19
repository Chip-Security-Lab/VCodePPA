module BusOR(
    input [15:0] bus_a, bus_b,
    output [15:0] bus_or
);
    assign bus_or = bus_a | bus_b;  // 16位总线操作
endmodule
