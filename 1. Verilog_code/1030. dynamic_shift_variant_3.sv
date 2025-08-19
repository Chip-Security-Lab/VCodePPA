//SystemVerilog
`timescale 1ns / 1ps

module dynamic_shift #(
    parameter W = 8
)(
    input  wire             clk,
    input  wire [3:0]       ctrl,   // [1:0]: direction, [3:2]: type
    input  wire [W-1:0]     din,
    output reg  [W-1:0]     dout
);

// Pipeline stage 1: Decode control and prepare operation type signals (No registers here)
wire [1:0] shift_type_wire;    // [1]: rotate, [0]: logical
wire [1:0] shift_dir_wire;     // [1]: right, [0]: left
wire [W-1:0] data_wire;

assign shift_type_wire = ctrl[3:2];
assign shift_dir_wire  = ctrl[1:0];
assign data_wire       = din;

// Pipeline stage 2: Perform shift/rotate operation, registers moved after combinational logic
reg [1:0] shift_type_stage2;
reg [1:0] shift_dir_stage2;
reg [W-1:0] data_stage2;

always @(posedge clk) begin
    shift_type_stage2 <= shift_type_wire;
    shift_dir_stage2  <= shift_dir_wire;
    data_stage2       <= data_wire;
end

// Pipeline stage 3: Shift/rotate operation result (register moved forward)
reg [W-1:0] shift_result_stage3;

always @(posedge clk) begin
    case ({shift_type_stage2, shift_dir_stage2})
        4'b0000: shift_result_stage3 <= data_stage2 << 1;                        // Logical left shift
        4'b0001: shift_result_stage3 <= data_stage2 >> 1;                        // Logical right shift
        4'b1000: shift_result_stage3 <= {data_stage2[W-2:0], data_stage2[W-1]};  // Rotate left
        4'b1001: shift_result_stage3 <= {data_stage2[0], data_stage2[W-1:1]};    // Rotate right
        default: shift_result_stage3 <= data_stage2;                             // Pass-through (for invalid ctrl)
    endcase
end

// Pipeline stage 4: Output register
always @(posedge clk) begin
    dout <= shift_result_stage3;
end

endmodule