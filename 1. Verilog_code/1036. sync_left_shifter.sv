module sync_left_shifter #(parameter W=32) (
  input Clock, Enable,
  input [W-1:0] DataIn,
  input [4:0] ShiftAmount,
  output reg [W-1:0] DataOut
);
  always @(posedge Clock) begin
    if (Enable)
      DataOut <= DataIn << ShiftAmount; // Logical left shift
    // No else to maintain value when disabled
  end
endmodule