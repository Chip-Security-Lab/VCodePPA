module code_converter (
    input [2:0] binary,
    output [2:0] gray,
    output [7:0] one_hot
);
    assign gray = binary ^ (binary >> 1);
    assign one_hot = 8'b1 << binary;
endmodule


