module nor2_instance (
    input wire A, B,
    output wire Y
);
    wire temp;
    or2 u1 (.A(A), .B(B), .Y(temp));  // 通过实例化一个或门
    assign Y = ~temp;  // 反转该输出，得到或非门
endmodule

module or2 (
    input wire A, B,
    output wire Y
);
    assign Y = A | B;  // Simple OR operation
endmodule