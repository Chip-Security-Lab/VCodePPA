module ora_and_inv(input a, b, c, output y);
    wire nor_out;
    or(nor_out, a, b);
    and(y, nor_out, ~c);  // 包含非门
endmodule