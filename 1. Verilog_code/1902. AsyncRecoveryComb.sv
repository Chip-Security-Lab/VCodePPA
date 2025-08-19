module AsyncRecoveryComb #(parameter WIDTH=8) (
    input [WIDTH-1:0] din,
    output [WIDTH-1:0] dout
);
    assign dout = din ^ (din << 1); // XOR噪声消除
endmodule
