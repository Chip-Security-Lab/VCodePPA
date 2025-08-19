module Sub2(input [3:0] x,y, output [3:0] diff, output borrow);
    assign {borrow, diff} = x - y;
endmodule