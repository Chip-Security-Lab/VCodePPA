module TMR_Recovery #(parameter WIDTH=8) (
    input [WIDTH-1:0] ch0, ch1, ch2,
    output [WIDTH-1:0] data_out
);
    assign data_out = (ch0 & ch1) | (ch1 & ch2) | (ch0 & ch2);
endmodule
