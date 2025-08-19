//SystemVerilog
// Top-level module: Hierarchical cyclic right shifter with barrel shifter
module shift_cycl_right_comb #(parameter WIDTH=8) (
    input  [WIDTH-1:0] din,
    input  [2:0]       shift_amt,
    output [WIDTH-1:0] dout
);

    wire [WIDTH-1:0] right_shifted;
    wire [WIDTH-1:0] left_shifted;

    // Barrel shifter for right shift
    barrel_shift_right #(.WIDTH(WIDTH)) u_barrel_shift_right (
        .data_in    (din),
        .shift_amt  (shift_amt),
        .data_out   (right_shifted)
    );

    // Barrel shifter for left shift
    barrel_shift_left #(.WIDTH(WIDTH)) u_barrel_shift_left (
        .data_in    (din),
        .shift_amt  (WIDTH - shift_amt),
        .data_out   (left_shifted)
    );

    // Combine the two shifted results using bitwise OR
    shift_or_unit #(.WIDTH(WIDTH)) u_shift_or (
        .in_data0   (right_shifted),
        .in_data1   (left_shifted),
        .out_data   (dout)
    );

endmodule

// -----------------------------------------------------------------------------
// Submodule: barrel_shift_right
// Function: Barrel shifter for logical right shift by a specified amount
// -----------------------------------------------------------------------------
module barrel_shift_right #(parameter WIDTH=8) (
    input  [WIDTH-1:0] data_in,
    input  [2:0]       shift_amt,
    output [WIDTH-1:0] data_out
);
    wire [WIDTH-1:0] stage0;
    wire [WIDTH-1:0] stage1;
    wire [WIDTH-1:0] stage2;

    // Shift by 1 if shift_amt[0] is set
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_stage0
            assign stage0[i] = shift_amt[0] ? ((i+1 < WIDTH) ? data_in[i+1] : 1'b0) : data_in[i];
        end
    endgenerate

    // Shift by 2 if shift_amt[1] is set
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_stage1
            assign stage1[i] = shift_amt[1] ? ((i+2 < WIDTH) ? stage0[i+2] : 1'b0) : stage0[i];
        end
    endgenerate

    // Shift by 4 if shift_amt[2] is set
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_stage2
            assign stage2[i] = shift_amt[2] ? ((i+4 < WIDTH) ? stage1[i+4] : 1'b0) : stage1[i];
        end
    endgenerate

    assign data_out = stage2;

endmodule

// -----------------------------------------------------------------------------
// Submodule: barrel_shift_left
// Function: Barrel shifter for logical left shift by a specified amount
// -----------------------------------------------------------------------------
module barrel_shift_left #(parameter WIDTH=8) (
    input  [WIDTH-1:0] data_in,
    input  [2:0]       shift_amt,
    output [WIDTH-1:0] data_out
);
    wire [WIDTH-1:0] stage0;
    wire [WIDTH-1:0] stage1;
    wire [WIDTH-1:0] stage2;

    // Shift by 1 if shift_amt[0] is set
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_stage0
            assign stage0[i] = shift_amt[0] ? ((i-1 >= 0) ? data_in[i-1] : 1'b0) : data_in[i];
        end
    endgenerate

    // Shift by 2 if shift_amt[1] is set
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_stage1
            assign stage1[i] = shift_amt[1] ? ((i-2 >= 0) ? stage0[i-2] : 1'b0) : stage0[i];
        end
    endgenerate

    // Shift by 4 if shift_amt[2] is set
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_stage2
            assign stage2[i] = shift_amt[2] ? ((i-4 >= 0) ? stage1[i-4] : 1'b0) : stage1[i];
        end
    endgenerate

    assign data_out = stage2;

endmodule

// -----------------------------------------------------------------------------
// Submodule: shift_or_unit
// Function: Bitwise OR of two input vectors
// -----------------------------------------------------------------------------
module shift_or_unit #(parameter WIDTH=8) (
    input  [WIDTH-1:0] in_data0,
    input  [WIDTH-1:0] in_data1,
    output [WIDTH-1:0] out_data
);
    assign out_data = in_data0 | in_data1;
endmodule