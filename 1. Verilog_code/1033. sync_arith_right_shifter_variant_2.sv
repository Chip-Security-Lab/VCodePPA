//SystemVerilog
module sync_arith_right_shifter (
  input wire clock, reset_n,
  input wire [7:0] data_in,
  input wire [2:0] shift_amount,
  output wire [7:0] result
);

  wire [7:0] arith_shift_result;

  assign arith_shift_result = $signed(data_in) >>> shift_amount;

  reg [7:0] result_reg;

  always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
      result_reg <= 8'b0;
    end else begin
      result_reg <= arith_shift_result;
    end
  end

  assign result = result_reg;

endmodule