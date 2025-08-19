module xor_ternary(input a, b, output y);
    assign y = (a === 1'bx || b === 1'bx) ? 1'bx : a ^ b;
endmodule