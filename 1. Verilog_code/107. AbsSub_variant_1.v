module AbsSub(
    input signed [7:0] x,
    input signed [7:0] y,
    output signed [7:0] res
);
    wire comp_out;
    wire signed [7:0] diff_xy;
    wire signed [7:0] diff_yx;
    
    Comparator comp_inst(
        .x(x),
        .y(y),
        .comp_result(comp_out)
    );
    
    Subtractor sub_xy(
        .a(x),
        .b(y),
        .diff(diff_xy)
    );
    
    Subtractor sub_yx(
        .a(y),
        .b(x),
        .diff(diff_yx)
    );
    
    Mux2to1 mux_inst(
        .sel(comp_out),
        .in0(diff_yx),
        .in1(diff_xy),
        .out(res)
    );
endmodule

module Comparator(
    input signed [7:0] x,
    input signed [7:0] y,
    output reg comp_result
);
    always @(*) begin
        comp_result = (x > y);
    end
endmodule

module Subtractor(
    input signed [7:0] a,
    input signed [7:0] b,
    output signed [7:0] diff
);
    wire signed [7:0] b_inv;
    wire signed [7:0] sum;
    wire carry;
    
    assign b_inv = ~b;
    assign {carry, sum} = a + b_inv + 1'b1;
    assign diff = sum;
endmodule

module Mux2to1(
    input sel,
    input signed [7:0] in0,
    input signed [7:0] in1,
    output signed [7:0] out
);
    assign out = sel ? in0 : in1;
endmodule