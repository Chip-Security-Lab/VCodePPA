//SystemVerilog
// Top-level module: sub_complement_8
module sub_complement_8 (
    input  wire [7:0] minuend,
    input  wire [7:0] subtrahend,
    output wire [7:0] difference
);

    // Intermediate signals for bitwise NOT and carry
    wire [7:0] subtrahend_inverted;
    wire [8:0] adder_sum;

    // Instance: bitwise_not_unit
    bitwise_not_unit #(.WIDTH(8)) u_bitwise_not_unit (
        .a      (subtrahend),
        .y      (subtrahend_inverted)
    );

    // Instance: adder_unit (minuend + ~subtrahend + 1)
    adder_unit #(.WIDTH(8)) u_adder_unit (
        .a      (minuend),
        .b      (subtrahend_inverted),
        .cin    (1'b1),
        .sum    (adder_sum)
    );

    assign difference = adder_sum[7:0];

endmodule

// Submodule: bitwise_not_unit
module bitwise_not_unit #(parameter WIDTH = 1) (
    input  wire [WIDTH-1:0] a,
    output wire [WIDTH-1:0] y
);
    assign y = ~a;
endmodule

// Submodule: adder_unit
module adder_unit #(parameter WIDTH = 1) (
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    input  wire             cin,
    output wire [WIDTH:0]   sum
);
    assign sum = a + b + cin;
endmodule