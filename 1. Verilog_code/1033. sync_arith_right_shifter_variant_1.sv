//SystemVerilog
module sync_arith_right_shifter (
  input wire clock,
  input wire reset_n,
  input wire [7:0] data_in,
  input wire [2:0] shift_by,
  output reg [7:0] result
);

  reg [7:0] data_in_reg;
  reg [2:0] shift_by_reg;

  always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
      data_in_reg <= 8'b0;
      shift_by_reg <= 3'b0;
    end else begin
      data_in_reg <= data_in;
      shift_by_reg <= shift_by;
    end
  end

  always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
      result <= 8'b0;
    end else begin
      result <= $signed(data_in_reg) >>> shift_by_reg;
    end
  end

endmodule