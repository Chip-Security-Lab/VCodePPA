module MultiDriveNOT(
    input [7:0] vector,
    output [7:0] inverse
);
    assign inverse[0] = ~vector[0];
    assign inverse[1] = !vector[1];  // 混合使用~和!运算符
    assign inverse[7:2] = ~vector[7:2];
endmodule
