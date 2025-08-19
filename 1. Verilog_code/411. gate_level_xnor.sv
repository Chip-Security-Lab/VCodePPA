module gate_level_xnor (a, b, y);
    input a, b;
    output y;
    xnor x1 (y, a, b);
endmodule