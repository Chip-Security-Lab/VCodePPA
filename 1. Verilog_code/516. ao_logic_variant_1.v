module ao_logic(
    input a, b, c, d,
    output y
);
    // 使用布尔代数简化: (a&b) | (c&d) = (a|~b)&(b|~a) | (c|~d)&(d|~c)
    wire ab, cd;
    assign ab = (a | ~b) & (b | ~a);
    assign cd = (c | ~d) & (d | ~c);
    assign y = ab | cd;
endmodule