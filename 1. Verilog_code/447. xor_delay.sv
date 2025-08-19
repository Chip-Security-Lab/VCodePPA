module xor_delay(input a, b, output y);
    assign #2 y = a ^ b;  // 传输延迟2ns
endmodule