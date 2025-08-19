//SystemVerilog
//-----------------------------------------------------------------------------
// Top-level Module: shift_dual_channel
// Function: Dual channel shift and subtract, hierarchical structure
//-----------------------------------------------------------------------------
module shift_dual_channel #(parameter WIDTH=8) (
    input  [WIDTH-1:0] din,
    output [WIDTH-1:0] left_out,
    output [WIDTH-1:0] right_out
);

    // Internal signals for shifted results
    wire [WIDTH-1:0] left_shifted;
    wire [WIDTH-1:0] right_shifted;

    // Internal signals for subtraction
    wire [WIDTH-1:0] left_sub_b;
    wire             left_sub_carry_in;
    wire             left_sub_carry_out;

    wire [WIDTH-1:0] right_sub_b;
    wire             right_sub_carry_in;
    wire             right_sub_carry_out;

    // Left logical shifter instance
    left_logical_shifter #(.WIDTH(WIDTH)) u_left_logical_shifter (
        .data_in   (din),
        .data_out  (left_shifted)
    );

    // Right logical shifter instance
    right_logical_shifter #(.WIDTH(WIDTH)) u_right_logical_shifter (
        .data_in   (din),
        .data_out  (right_shifted)
    );

    // Generate subtrahend and carry-in for left subtractor
    assign left_sub_b = ~din;
    assign left_sub_carry_in = 1'b1;

    // Generate subtrahend and carry-in for right subtractor
    assign right_sub_b = ~din;
    assign right_sub_carry_in = 1'b1;

    // Left subtractor: left_out = left_shifted - din
    conditional_sum_subtractor #(.WIDTH(WIDTH)) u_left_subtractor (
        .a    (left_shifted),
        .b    (left_sub_b),
        .cin  (left_sub_carry_in),
        .sum  (left_out),
        .cout (left_sub_carry_out)
    );

    // Right subtractor: right_out = right_shifted - din
    conditional_sum_subtractor #(.WIDTH(WIDTH)) u_right_subtractor (
        .a    (right_shifted),
        .b    (right_sub_b),
        .cin  (right_sub_carry_in),
        .sum  (right_out),
        .cout (right_sub_carry_out)
    );

endmodule

//-----------------------------------------------------------------------------
// Module: left_logical_shifter
// Function: Performs logical left shift by 1 bit (fills LSB with 0)
//-----------------------------------------------------------------------------
module left_logical_shifter #(parameter WIDTH=8) (
    input  [WIDTH-1:0] data_in,
    output [WIDTH-1:0] data_out
);
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_left_shift
            if (i == 0) begin
                assign data_out[i] = 1'b0;
            end else begin
                assign data_out[i] = data_in[i-1];
            end
        end
    endgenerate
endmodule

//-----------------------------------------------------------------------------
// Module: right_logical_shifter
// Function: Performs logical right shift by 1 bit (fills MSB with 0)
//-----------------------------------------------------------------------------
module right_logical_shifter #(parameter WIDTH=8) (
    input  [WIDTH-1:0] data_in,
    output [WIDTH-1:0] data_out
);
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_right_shift
            if (i == WIDTH-1) begin
                assign data_out[i] = 1'b0;
            end else begin
                assign data_out[i] = data_in[i+1];
            end
        end
    endgenerate
endmodule

//-----------------------------------------------------------------------------
// Module: conditional_sum_subtractor
// Function: Adds or subtracts two WIDTH-bit numbers, ripple-carry structure
//-----------------------------------------------------------------------------
module conditional_sum_subtractor #(parameter WIDTH=8) (
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    input              cin,
    output [WIDTH-1:0] sum,
    output             cout
);
    wire [WIDTH:0] carry;
    assign carry[0] = cin;

    genvar j;
    generate
        for (j = 0; j < WIDTH; j = j + 1) begin : bit_adder
            assign sum[j] = a[j] ^ b[j] ^ carry[j];
            assign carry[j+1] = (a[j] & b[j]) | (a[j] & carry[j]) | (b[j] & carry[j]);
        end
    endgenerate

    assign cout = carry[WIDTH];
endmodule