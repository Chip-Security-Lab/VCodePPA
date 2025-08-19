//SystemVerilog
module sync_left_shifter #(parameter W=32) (
  input wire Clock,
  input wire Enable,
  input wire [W-1:0] DataIn,
  input wire [4:0] ShiftAmount,
  output reg [W-1:0] DataOut
);

  wire [W-1:0] stage_0;
  wire [W-1:0] stage_1;
  wire [W-1:0] stage_2;
  wire [W-1:0] stage_3;
  wire [W-1:0] stage_4;

  // Balanced barrel shifter logic for improved timing
  assign stage_0 = ShiftAmount[0] ? {DataIn[W-2:0], 1'b0}           : DataIn;
  assign stage_1 = ShiftAmount[1] ? {stage_0[W-3:0], 2'b00}          : stage_0;
  assign stage_2 = ShiftAmount[2] ? {stage_1[W-5:0], 4'b0000}        : stage_1;
  assign stage_3 = ShiftAmount[3] ? {stage_2[W-9:0], 8'b00000000}    : stage_2;
  assign stage_4 = ShiftAmount[4] ? {stage_3[W-17:0], 16'b0}         : stage_3;

  always @(posedge Clock) begin
    if (Enable)
      DataOut <= stage_4;
  end

endmodule