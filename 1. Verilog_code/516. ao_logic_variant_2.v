// 顶层模块
module ao_logic_top(
    input a, b, c, d,
    output y
);
    wire w1, w2, w3, w4;
    
    // 实例化子模块
    ao_or2 u_or2_1(.a(a), .b(c), .y(w1));
    ao_or2 u_or2_2(.a(a), .b(d), .y(w2)); 
    ao_or2 u_or2_3(.a(b), .b(c), .y(w3));
    ao_or2 u_or2_4(.a(b), .b(d), .y(w4));
    
    ao_and4 u_and4(.a(w1), .b(w2), .c(w3), .d(w4), .y(y));

endmodule

// 2输入或门子模块
module ao_or2(
    input a, b,
    output y
);
    assign y = a | b;
endmodule

// 4输入与门子模块
module ao_and4(
    input a, b, c, d,
    output y
);
    assign y = a & b & c & d;
endmodule