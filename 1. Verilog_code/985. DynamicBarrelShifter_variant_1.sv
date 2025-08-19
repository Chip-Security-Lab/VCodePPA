//SystemVerilog
// -----------------------------------------------------------------------
// Top-level Module: DynamicBarrelShifter
// Function: Parameterized dynamic (left) barrel shifter with modular hierarchy
// -----------------------------------------------------------------------
module DynamicBarrelShifter #(
    parameter MAX_SHIFT = 4,
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0]           data_in,
    input  wire [MAX_SHIFT-1:0]       shift_val,
    output wire [WIDTH-1:0]           data_out
);

    // Internal signal to connect shifter stages
    wire [WIDTH-1:0] stage_data [0:MAX_SHIFT];

    // Assign input to first stage
    assign stage_data[0] = data_in;

    // Generate shifter stages using while-loop unrolled as per IEEE 1364-2005
    // as generate blocks do not support while, use equivalent manual unrolling
    // for MAX_SHIFT = 4 (default), can be parameterized up to synthesis tool capabilities

    // Stage 0
    BarrelShifterStage #(
        .WIDTH(WIDTH),
        .SHIFT_AMOUNT(1 << 0)
    ) u_stage0 (
        .data_in(stage_data[0]),
        .shift_enable(shift_val[0]),
        .data_out(stage_data[1])
    );

    // Stage 1
    BarrelShifterStage #(
        .WIDTH(WIDTH),
        .SHIFT_AMOUNT(1 << 1)
    ) u_stage1 (
        .data_in(stage_data[1]),
        .shift_enable(shift_val[1]),
        .data_out(stage_data[2])
    );

    // Stage 2
    BarrelShifterStage #(
        .WIDTH(WIDTH),
        .SHIFT_AMOUNT(1 << 2)
    ) u_stage2 (
        .data_in(stage_data[2]),
        .shift_enable(shift_val[2]),
        .data_out(stage_data[3])
    );

    // Stage 3
    BarrelShifterStage #(
        .WIDTH(WIDTH),
        .SHIFT_AMOUNT(1 << 3)
    ) u_stage3 (
        .data_in(stage_data[3]),
        .shift_enable(shift_val[3]),
        .data_out(stage_data[4])
    );

    // Assign output from last stage
    assign data_out = stage_data[MAX_SHIFT];

endmodule

// -----------------------------------------------------------------------
// Submodule: BarrelShifterStage
// Function: Shift input left by parameterized amount if enabled
// Inputs:
//   - data_in      : Input data word
//   - shift_enable : Shift enable for this stage
// Outputs:
//   - data_out     : Shifted data
// -----------------------------------------------------------------------
module BarrelShifterStage #(
    parameter WIDTH = 8,
    parameter SHIFT_AMOUNT = 1
)(
    input  wire [WIDTH-1:0] data_in,
    input  wire             shift_enable,
    output wire [WIDTH-1:0] data_out
);

    assign data_out = shift_enable ? (data_in << SHIFT_AMOUNT) : data_in;

endmodule