module and_or (input a, b, c, d, output y);
    wire w1, w2;
    and(w1, a, b);
    or(w2, c, d);
    xor(y, w1, w2);  // 混合三种逻辑门
endmodule