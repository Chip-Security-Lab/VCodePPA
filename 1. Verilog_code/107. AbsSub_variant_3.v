// Top module
module AbsSub(
    input signed [7:0] x,
    input signed [7:0] y,
    output signed [7:0] res
);
    wire x_greater;
    wire signed [7:0] diff1, diff2;
    
    Comparator comp_inst(
        .x(x),
        .y(y),
        .x_greater(x_greater)
    );
    
    Subtractor sub1_inst(
        .a(x),
        .b(y),
        .diff(diff1)
    );
    
    Subtractor sub2_inst(
        .a(y),
        .b(x),
        .diff(diff2)
    );
    
    assign res = x_greater ? diff1 : diff2;
endmodule

// Comparator module
module Comparator(
    input signed [7:0] x,
    input signed [7:0] y,
    output reg x_greater
);
    always @(*) begin
        x_greater = (x > y);
    end
endmodule

// Subtraction module
module Subtractor(
    input signed [7:0] a,
    input signed [7:0] b,
    output signed [7:0] diff
);
    assign diff = a - b;
endmodule