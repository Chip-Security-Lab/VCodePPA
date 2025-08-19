//SystemVerilog

// Submodule for parallel prefix adder
module prefix_adder #(parameter WIDTH = 8)(
    input [WIDTH-1:0] a, b,
    input cin,
    output [WIDTH-1:0] sum,
    output cout
);

    wire [WIDTH-1:0] gen, prop;
    wire [WIDTH:0] carry;

    assign gen = a & b;
    assign prop = a ^ b;

    // Parallel prefix tree for carries
    // This is a simplified example, a real implementation would use a proper tree structure
    // for better performance and scalability.
    assign carry[0] = cin;
    genvar i;
    for (i = 0; i < WIDTH; i = i + 1) begin : carry_chain
        assign carry[i+1] = gen[i] | (prop[i] & carry[i]);
    end

    assign sum = prop ^ carry[WIDTH-1:0];
    assign cout = carry[WIDTH];

endmodule

// Submodule for parallel prefix subtractor
module prefix_subtractor #(parameter WIDTH = 8)(
    input [WIDTH-1:0] a, b,
    output [WIDTH-1:0] diff
);

    wire [WIDTH-1:0] b_inv;
    wire cout;

    assign b_inv = ~b;

    // a - b = a + (~b) + 1
    prefix_adder #(WIDTH) adder (
        .a(a),
        .b(b_inv),
        .cin(1'b1), // Add 1 for 2's complement subtraction
        .sum(diff),
        .cout(cout) // Carry out can be used for overflow detection
    );

endmodule

// Submodule for priority encoder
module priority_encoder #(parameter WIDTH = 8)(
    input [WIDTH-1:0] value,
    output [$clog2(WIDTH)-1:0] priority_bit
);

    function [$clog2(WIDTH)-1:0] find_msb;
        input [WIDTH-1:0] val;
        integer i;
        begin
            find_msb = 0;
            for (i = WIDTH-1; i >= 0; i = i - 1)
                if (val[i]) begin
                    find_msb = i[$clog2(WIDTH)-1:0];
                    // Only need to find the first set bit from MSB
                    // break; // Uncomment if synthesis tool supports break in functions
                end
        end
    endfunction

    assign priority_bit = find_msb(value);

endmodule

// Top-level module for asynchronous magnitude comparison
module async_magnitude_comp #(parameter WIDTH = 8)(
    input [WIDTH-1:0] a, b,
    output [WIDTH-1:0] diff_magnitude,
    output [$clog2(WIDTH)-1:0] priority_bit,
    output a_larger
);

    wire [WIDTH-1:0] sub_ab_diff;
    wire [WIDTH-1:0] sub_ba_diff;
    wire [WIDTH-1:0] difference;

    assign a_larger = a > b;

    // Instantiate subtractor for a - b
    prefix_subtractor #(WIDTH) sub_ab (
        .a(a),
        .b(b),
        .diff(sub_ab_diff)
    );

    // Instantiate subtractor for b - a
    prefix_subtractor #(WIDTH) sub_ba (
        .a(b),
        .b(a),
        .diff(sub_ba_diff)
    );

    // Select the difference based on which number is larger
    assign difference = a_larger ? sub_ab_diff : sub_ba_diff;
    assign diff_magnitude = difference;

    // Instantiate priority encoder to find the MSB of the magnitude
    priority_encoder #(WIDTH) msb_encoder (
        .value(difference),
        .priority_bit(priority_bit)
    );

endmodule