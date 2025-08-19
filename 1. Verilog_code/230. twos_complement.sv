module twos_complement (
    input signed [3:0] value,
    output [3:0] absolute,
    output [3:0] negative
);
    assign absolute = value >= 0 ? value : -value;
    assign negative = -value;
endmodule
