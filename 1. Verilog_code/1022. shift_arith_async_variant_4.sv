//SystemVerilog
module shift_arith_async #(parameter W=8) (
    input  wire signed [W-1:0] din,
    input  wire [2:0] shift,
    output wire signed [W-1:0] dout
);

    // Stage 0: Input Registering
    wire signed [W-1:0] din_wire = din;
    wire [2:0] shift_wire = shift;

    // Stage 1: Shift by 1 if shift_wire[0] is set
    wire signed [W-1:0] stage1_data;
    assign stage1_data = shift_wire[0] ? {din_wire[W-1], din_wire[W-1:1]} : din_wire;

    // Stage 2: Shift by 2 if shift_wire[1] is set
    wire signed [W-1:0] stage2_data;
    assign stage2_data = shift_wire[1] ? {{2{stage1_data[W-1]}}, stage1_data[W-1:2]} : stage1_data;

    // Stage 3: Shift by 4 if shift_wire[2] is set
    wire signed [W-1:0] stage3_data;
    assign stage3_data = shift_wire[2] ? {{4{stage2_data[W-1]}}, stage2_data[W-1:4]} : stage2_data;

    // Output Assignment
    assign dout = stage3_data;

endmodule