//SystemVerilog
// Top-level module for asynchronous logical right shifter with hierarchical structure
module async_logical_right_shifter #(
    parameter DATA_WIDTH = 16,
    parameter SHIFT_WIDTH = 4
)(
    input  [DATA_WIDTH-1:0] in_data,
    input  [SHIFT_WIDTH-1:0] shift_amount,
    output [DATA_WIDTH-1:0] out_data
);

    wire [DATA_WIDTH-1:0] stage0_to_stage1;
    wire [DATA_WIDTH-1:0] stage1_to_stage2;
    wire [DATA_WIDTH-1:0] stage2_to_stage3;
    wire [DATA_WIDTH-1:0] stage3_to_out;

    // Stage 0: Shift by 1 bit if shift_amount[0] is set
    shift_stage #(
        .DATA_WIDTH(DATA_WIDTH),
        .SHIFT_AMOUNT(1)
    ) shift_stage0 (
        .in_data(in_data),
        .shift_ctrl(shift_amount[0]),
        .out_data(stage0_to_stage1)
    );

    // Stage 1: Shift by 2 bits if shift_amount[1] is set
    shift_stage #(
        .DATA_WIDTH(DATA_WIDTH),
        .SHIFT_AMOUNT(2)
    ) shift_stage1 (
        .in_data(stage0_to_stage1),
        .shift_ctrl(shift_amount[1]),
        .out_data(stage1_to_stage2)
    );

    // Stage 2: Shift by 4 bits if shift_amount[2] is set
    shift_stage #(
        .DATA_WIDTH(DATA_WIDTH),
        .SHIFT_AMOUNT(4)
    ) shift_stage2 (
        .in_data(stage1_to_stage2),
        .shift_ctrl(shift_amount[2]),
        .out_data(stage2_to_stage3)
    );

    // Stage 3: Shift by 8 bits if shift_amount[3] is set
    shift_stage #(
        .DATA_WIDTH(DATA_WIDTH),
        .SHIFT_AMOUNT(8)
    ) shift_stage3 (
        .in_data(stage2_to_stage3),
        .shift_ctrl(shift_amount[3]),
        .out_data(stage3_to_out)
    );

    assign out_data = stage3_to_out;

endmodule

// -----------------------------------------------------------------------------
// Submodule: shift_stage
// Performs logical right shift by parameterized amount if shift_ctrl is high
// -----------------------------------------------------------------------------
module shift_stage #(
    parameter DATA_WIDTH = 16,
    parameter SHIFT_AMOUNT = 1
)(
    input  [DATA_WIDTH-1:0] in_data,
    input                   shift_ctrl,
    output [DATA_WIDTH-1:0] out_data
);
    reg [DATA_WIDTH-1:0] shift_result;

    always @* begin
        if (shift_ctrl) begin
            shift_result = { {SHIFT_AMOUNT{1'b0}}, in_data[DATA_WIDTH-1:SHIFT_AMOUNT] };
        end else begin
            shift_result = in_data;
        end
    end

    assign out_data = shift_result;
endmodule