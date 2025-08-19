//SystemVerilog
// Top-level module: Hierarchical Dynamic Barrel Shifter
module DynamicBarrelShifter #(parameter MAX_SHIFT=4, WIDTH=8) (
    input  [WIDTH-1:0]      data_in,
    input  [MAX_SHIFT-1:0]  shift_val,
    output [WIDTH-1:0]      data_out
);

    // Internal wires for submodule interconnections
    wire [MAX_SHIFT-1:0]    shift_val_inverted;
    wire [MAX_SHIFT:0]      shift_val_extended;
    wire [WIDTH-1:0]        barrel_shift_result;

    // Instantiate Two's Complement Inverter for shift_val
    TwosComplementInverter #(.WIDTH(MAX_SHIFT)) u_shiftval_inverter (
        .in_value    (shift_val),
        .inv_value   (shift_val_inverted)
    );

    // Instantiate Shift Value Extender for two's complement extension using conditional sum subtractor
    ShiftValueExtender_CondSum #(.WIDTH(MAX_SHIFT)) u_shiftval_extender (
        .inv_value   (shift_val_inverted),
        .ext_value   (shift_val_extended)
    );

    // Instantiate Barrel Shifter
    BarrelShifter #(.WIDTH(WIDTH), .MAX_SHIFT(MAX_SHIFT)) u_barrel_shifter (
        .data_in     (data_in),
        .shift_val   (shift_val),
        .shift_out   (barrel_shift_result)
    );

    // Output assignment
    assign data_out = barrel_shift_result;

endmodule

// -----------------------------------------------------------------------------
// Submodule: TwosComplementInverter
// Function: Computes bitwise inversion of input and outputs result
// -----------------------------------------------------------------------------
module TwosComplementInverter #(parameter WIDTH=4) (
    input  [WIDTH-1:0]  in_value,
    output [WIDTH-1:0]  inv_value
);
    assign inv_value = ~in_value;
endmodule

// -----------------------------------------------------------------------------
// Submodule: ShiftValueExtender_CondSum
// Function: Extends the inverted value and adds 1 (two's complement) using conditional sum subtractor
// -----------------------------------------------------------------------------
module ShiftValueExtender_CondSum #(parameter WIDTH=4) (
    input  [WIDTH-1:0]   inv_value,
    output [WIDTH:0]     ext_value
);
    wire [WIDTH-1:0]     conditional_sum;
    wire                 carry_out;

    // Conditional sum subtractor for (inv_value + 1)
    ConditionalSumAdder #(.WIDTH(WIDTH)) u_cond_sum_adder (
        .a            (inv_value),
        .b            ({(WIDTH){1'b0}}),
        .cin          (1'b1),
        .sum          (conditional_sum),
        .cout         (carry_out)
    );

    assign ext_value = {carry_out, conditional_sum};
endmodule

// -----------------------------------------------------------------------------
// Submodule: ConditionalSumAdder
// Function: Adds two WIDTH-bit numbers and a carry-in using conditional sum algorithm
// -----------------------------------------------------------------------------
module ConditionalSumAdder #(parameter WIDTH=4) (
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    input              cin,
    output [WIDTH-1:0] sum,
    output             cout
);
    // Internal wires for group sums and carries
    wire [WIDTH-1:0]   sum_carry0;
    wire [WIDTH-1:0]   sum_carry1;
    wire [WIDTH:0]     carry;

    assign carry[0] = cin;

    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : cond_sum_gen
            // Compute sum and carry for carry-in = 0
            assign sum_carry0[i] = a[i] ^ b[i] ^ 1'b0 ^ carry[i];
            assign carry_carry0 = (a[i] & b[i]) | (a[i] & carry[i]) | (b[i] & carry[i]);

            // Compute sum and carry for carry-in = 1
            assign sum_carry1[i] = a[i] ^ b[i] ^ 1'b1 ^ carry[i];
            assign carry_carry1 = (a[i] & b[i]) | (a[i] & carry[i]) | (b[i] & carry[i]);

            // Select correct sum and carry based on previous carry
            assign sum[i]  = (carry[i] == 1'b0) ? sum_carry0[i] : sum_carry1[i];
            assign carry[i+1] = (carry[i] == 1'b0) ? carry_carry0 : carry_carry1;
        end
    endgenerate

    assign cout = carry[WIDTH];
endmodule

// -----------------------------------------------------------------------------
// Submodule: BarrelShifter
// Function: Performs left shift operation on input data
// -----------------------------------------------------------------------------
module BarrelShifter #(parameter WIDTH=8, MAX_SHIFT=4) (
    input  [WIDTH-1:0]      data_in,
    input  [MAX_SHIFT-1:0]  shift_val,
    output [WIDTH-1:0]      shift_out
);
    assign shift_out = data_in << shift_val;
endmodule