module xor2_7 #(parameter WIDTH = 8) (
    input wire [WIDTH-1:0] A, B,
    output wire [WIDTH-1:0] Y
);
    assign Y = A ^ B; // 位宽可配置的异或门
endmodule
