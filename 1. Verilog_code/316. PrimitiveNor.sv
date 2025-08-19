module PrimitiveNor(input a, b, output y);
    nor(y, a, b); // 使用门级原语
endmodule