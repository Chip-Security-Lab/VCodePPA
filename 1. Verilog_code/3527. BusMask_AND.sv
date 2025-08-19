module BusMask_AND(
    input [15:0] bus_in,
    input [15:0] mask,
    output [15:0] masked_bus
);
    assign masked_bus = bus_in & mask; // 总线掩码操作
endmodule
