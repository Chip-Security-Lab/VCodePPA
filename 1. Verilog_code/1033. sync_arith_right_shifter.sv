module sync_arith_right_shifter (
  input wire clock, reset_n,
  input wire [7:0] data_in,
  input wire [2:0] shift_by,
  output reg [7:0] result
);
  always @(posedge clock or negedge reset_n) begin
    if (!reset_n)
      result <= 8'b0;
    else begin
      // Arithmetic right shift preserves sign bit
      result <= $signed(data_in) >>> shift_by;
    end
  end
endmodule