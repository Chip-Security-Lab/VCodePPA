module nor_gate(input a, b, output y);
    assign y = ~(a | b);
endmodule

module and_gate(input a, b, output y);
    assign y = a & b;
endmodule

module inv_gate(input a, output y);
    assign y = ~a;
endmodule

module nor_and_inv(input a, b, c, output y);
    wire nor_out;
    wire inv_c;
    
    nor_gate u_nor(.a(a), .b(b), .y(nor_out));
    inv_gate u_inv(.a(c), .y(inv_c));
    and_gate u_and(.a(nor_out), .b(inv_c), .y(y));
endmodule