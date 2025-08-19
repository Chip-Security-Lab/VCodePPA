module top_module(input a, b, c, output y);
    assign y = ~(a | b) & ~c;
endmodule