//SystemVerilog
// Top-level barrel shifter module with hierarchical structure
module barrel_shifter (
    input  wire [7:0] data_in,       // Input data
    input  wire [2:0] shift_amt,     // Shift amount
    input  wire       direction,     // 0: right, 1: left
    output wire [7:0] shifted_out    // Shifted result
);

    wire [7:0] left_shift_result;
    wire [7:0] right_shift_result;

    // Left shifter submodule instance
    left_shifter #(
        .WIDTH(8)
    ) u_left_shifter (
        .in_data(data_in),
        .shift_amount(shift_amt),
        .shifted_data(left_shift_result)
    );

    // Right shifter submodule instance
    right_shifter #(
        .WIDTH(8)
    ) u_right_shifter (
        .in_data(data_in),
        .shift_amount(shift_amt),
        .shifted_data(right_shift_result)
    );

    // Output multiplexer submodule instance
    shift_output_mux #(
        .WIDTH(8)
    ) u_shift_output_mux (
        .left_data(left_shift_result),
        .right_data(right_shift_result),
        .direction(direction),
        .shifted_out(shifted_out)
    );

endmodule

// ---------------------------------------------------------------------------
// Module: left_shifter
// Function: Performs logical left shift on input data by specified amount
//        using barrel shifter structure (MUX-based)
// ---------------------------------------------------------------------------
module left_shifter #(
    parameter WIDTH = 8
) (
    input  wire [WIDTH-1:0] in_data,
    input  wire [2:0]       shift_amount,
    output wire [WIDTH-1:0] shifted_data
);
    wire [WIDTH-1:0] stage0;
    wire [WIDTH-1:0] stage1;
    wire [WIDTH-1:0] stage2;

    // Stage 0: shift by 1 if shift_amount[0]
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_left_stage0
            assign stage0[i] = shift_amount[0] ?
                ((i >= 1) ? in_data[i-1] : 1'b0) :
                in_data[i];
        end
    endgenerate

    // Stage 1: shift by 2 if shift_amount[1]
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_left_stage1
            assign stage1[i] = shift_amount[1] ?
                ((i >= 2) ? stage0[i-2] : 1'b0) :
                stage0[i];
        end
    endgenerate

    // Stage 2: shift by 4 if shift_amount[2]
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_left_stage2
            assign stage2[i] = shift_amount[2] ?
                ((i >= 4) ? stage1[i-4] : 1'b0) :
                stage1[i];
        end
    endgenerate

    assign shifted_data = stage2;

endmodule

// ---------------------------------------------------------------------------
// Module: right_shifter
// Function: Performs logical right shift on input data by specified amount
//        using barrel shifter structure (MUX-based)
// ---------------------------------------------------------------------------
module right_shifter #(
    parameter WIDTH = 8
) (
    input  wire [WIDTH-1:0] in_data,
    input  wire [2:0]       shift_amount,
    output wire [WIDTH-1:0] shifted_data
);
    wire [WIDTH-1:0] stage0;
    wire [WIDTH-1:0] stage1;
    wire [WIDTH-1:0] stage2;

    // Stage 0: shift by 1 if shift_amount[0]
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_right_stage0
            assign stage0[i] = shift_amount[0] ?
                ((i <= WIDTH-2) ? in_data[i+1] : 1'b0) :
                in_data[i];
        end
    endgenerate

    // Stage 1: shift by 2 if shift_amount[1]
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_right_stage1
            assign stage1[i] = shift_amount[1] ?
                ((i <= WIDTH-3) ? stage0[i+2] : 1'b0) :
                stage0[i];
        end
    endgenerate

    // Stage 2: shift by 4 if shift_amount[2]
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_right_stage2
            assign stage2[i] = shift_amount[2] ?
                ((i <= WIDTH-5) ? stage1[i+4] : 1'b0) :
                stage1[i];
        end
    endgenerate

    assign shifted_data = stage2;

endmodule

// ---------------------------------------------------------------------------
// Module: shift_output_mux
// Function: Selects between left and right shifted data based on direction
// ---------------------------------------------------------------------------
module shift_output_mux #(
    parameter WIDTH = 8
) (
    input  wire [WIDTH-1:0] left_data,
    input  wire [WIDTH-1:0] right_data,
    input  wire             direction,   // 0: right, 1: left
    output wire [WIDTH-1:0] shifted_out
);
    assign shifted_out = direction ? left_data : right_data;
endmodule