//SystemVerilog
// Binary Search Division - Top Module
module BinSearchDiv(
    input [7:0] D, d,
    output [7:0] Q
);
    wire [7:0] low_out, high_out;
    wire [7:0] mid_out;
    wire [7:0] sum_out;
    wire carry_out;

    // Instantiate control module
    BinSearchControl control(
        .D(D),
        .d(d),
        .low_in(8'd0),
        .high_in(D),
        .low_out(low_out),
        .high_out(high_out)
    );

    // Instantiate midpoint calculation module
    MidpointCalc midpoint(
        .low(low_out),
        .high(high_out),
        .mid(mid_out)
    );

    // Instantiate multiplication module
    Multiplier mult(
        .a(mid_out),
        .b(d),
        .sum(sum_out),
        .carry(carry_out)
    );

    // Instantiate result selection module
    ResultSelector result_sel(
        .sum(sum_out),
        .D(D),
        .high(high_out),
        .Q(Q)
    );
endmodule

// Binary Search Control Module
module BinSearchControl(
    input [7:0] D, d,
    input [7:0] low_in, high_in,
    output reg [7:0] low_out, high_out
);
    wire [7:0] mid;
    wire [7:0] sum;
    wire carry;

    // Instantiate midpoint calculation module
    MidpointCalc midpoint(
        .low(low_in),
        .high(high_in),
        .mid(mid)
    );

    // Instantiate multiplication module
    Multiplier mult(
        .a(mid),
        .b(d),
        .sum(sum),
        .carry(carry)
    );

    always @(*) begin
        if (sum <= D) begin
            low_out = mid + 1;
            high_out = high_in;
        end else begin
            low_out = low_in;
            high_out = mid - 1;
        end
    end
endmodule

// Midpoint Calculation Module
module MidpointCalc(
    input [7:0] low, high,
    output reg [7:0] mid
);
    always @(*) begin
        mid = (low + high) >> 1;
    end
endmodule

// Multiplier Module
module Multiplier(
    input [7:0] a, b,
    output reg [7:0] sum,
    output reg carry
);
    always @(*) begin
        {carry, sum} = a * b;
    end
endmodule

// Result Selector Module
module ResultSelector(
    input [7:0] sum,
    input [7:0] D,
    input [7:0] high,
    output reg [7:0] Q
);
    always @(*) begin
        Q = high;
    end
endmodule