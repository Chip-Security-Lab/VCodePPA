//SystemVerilog
module shift_dual_channel #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] din,
    output wire [WIDTH-1:0] left_out,
    output wire [WIDTH-1:0] right_out
);

    // Pipeline stage 1: Capture input
    wire [WIDTH-1:0] din_stage1;
    assign din_stage1 = din;

    // Pipeline stage 2: Left shift and right shift pre-processing
    wire [WIDTH-2:0] left_shift_stage2;
    wire             lsb_stage2;
    wire [WIDTH-1:0] right_shift_stage2;

    assign left_shift_stage2 = din_stage1[WIDTH-2:0];
    assign lsb_stage2        = din_stage1[0];
    assign right_shift_stage2 = {1'b0, din_stage1[WIDTH-1:1]};

    // Pipeline stage 3: Output assignment
    assign left_out  = {left_shift_stage2, 1'b0};

    // Right shift with LSB subtraction
    wire [WIDTH-1:0] right_shift_lsb_sub;
    assign right_shift_lsb_sub = right_shift_stage2 - {{WIDTH-1{1'b0}}, lsb_stage2};
    assign right_out = right_shift_lsb_sub;

endmodule