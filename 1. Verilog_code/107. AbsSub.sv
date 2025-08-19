module AbsSub(input signed [7:0] x,y, output signed [7:0] res);
    assign res = (x > y) ? x - y : y - x;
endmodule