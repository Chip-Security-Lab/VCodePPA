module TwoCompSub(input signed [7:0] a,b, output signed [7:0] res);
    assign res = a + (-b);
endmodule