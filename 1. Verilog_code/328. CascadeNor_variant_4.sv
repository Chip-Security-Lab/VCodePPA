//SystemVerilog
module CascadeNor(input a, b, c, output y1, y2);
    assign y1 = ~a & ~b;
    assign y2 = ~a & ~b & ~c;
endmodule