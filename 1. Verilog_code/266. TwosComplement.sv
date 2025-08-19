module TwosComplement(
    input signed [15:0] number,
    output [15:0] complement
);
    assign complement = ~number + 1;  // 二进制补码
endmodule
