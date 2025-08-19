//SystemVerilog
module sync_left_shifter #(parameter W=32) (
  input Clock,
  input Enable,
  input [W-1:0] DataIn,
  input [4:0] ShiftAmount,
  output reg [W-1:0] DataOut
);

  // 5-bit conditional inversion subtractor for shift amount
  wire [4:0] shift_amount_inverted;
  wire       subtract_carry;
  wire [4:0] effective_shift_amt;

  assign shift_amount_inverted = ~ShiftAmount;
  assign subtract_carry = 1'b1; // For subtraction: A + ~B + 1

  // Conditional inversion adder (subtract ShiftAmount from 0)
  wire [4:0] subtract_sum;
  wire       subtract_carry_out;

  assign {subtract_carry_out, subtract_sum} = 5'b00000 + shift_amount_inverted + subtract_carry;
  assign effective_shift_amt = subtract_sum; // This computes (0 - ShiftAmount)

  // Shift result register
  reg [W-1:0] shift_result;

  // Shift operation block
  always @(*) begin
    case (ShiftAmount)
      5'd0:   shift_result = DataIn;
      5'd1:   shift_result = {DataIn[W-2:0], 1'b0};
      5'd2:   shift_result = {DataIn[W-3:0], 2'b00};
      5'd3:   shift_result = {DataIn[W-4:0], 3'b000};
      5'd4:   shift_result = {DataIn[W-5:0], 4'b0000};
      5'd5:   shift_result = {DataIn[W-6:0], 5'b00000};
      5'd6:   shift_result = {DataIn[W-7:0], 6'b000000};
      5'd7:   shift_result = {DataIn[W-8:0], 7'b0000000};
      5'd8:   shift_result = {DataIn[W-9:0], 8'b00000000};
      5'd9:   shift_result = {DataIn[W-10:0], 9'b000000000};
      5'd10:  shift_result = {DataIn[W-11:0], 10'b0000000000};
      5'd11:  shift_result = {DataIn[W-12:0], 11'b00000000000};
      5'd12:  shift_result = {DataIn[W-13:0], 12'b000000000000};
      5'd13:  shift_result = {DataIn[W-14:0], 13'b0000000000000};
      5'd14:  shift_result = {DataIn[W-15:0], 14'b00000000000000};
      5'd15:  shift_result = {DataIn[W-16:0], 15'b000000000000000};
      5'd16:  shift_result = {DataIn[W-17:0], 16'b0000000000000000};
      5'd17:  shift_result = {DataIn[W-18:0], 17'b00000000000000000};
      5'd18:  shift_result = {DataIn[W-19:0], 18'b000000000000000000};
      5'd19:  shift_result = {DataIn[W-20:0], 19'b0000000000000000000};
      5'd20:  shift_result = {DataIn[W-21:0], 20'b00000000000000000000};
      5'd21:  shift_result = {DataIn[W-22:0], 21'b000000000000000000000};
      5'd22:  shift_result = {DataIn[W-23:0], 22'b0000000000000000000000};
      5'd23:  shift_result = {DataIn[W-24:0], 23'b00000000000000000000000};
      5'd24:  shift_result = {DataIn[W-25:0], 24'b000000000000000000000000};
      5'd25:  shift_result = {DataIn[W-26:0], 25'b0000000000000000000000000};
      5'd26:  shift_result = {DataIn[W-27:0], 26'b00000000000000000000000000};
      5'd27:  shift_result = {DataIn[W-28:0], 27'b000000000000000000000000000};
      5'd28:  shift_result = {DataIn[W-29:0], 28'b0000000000000000000000000000};
      5'd29:  shift_result = {DataIn[W-30:0], 29'b00000000000000000000000000000};
      5'd30:  shift_result = {DataIn[W-31:0], 30'b000000000000000000000000000000};
      5'd31:  shift_result = {DataIn[0], {W-1{1'b0}}};
      default: shift_result = DataIn;
    endcase
  end

  // Output register block
  always @(posedge Clock) begin
    if (Enable) begin
      DataOut <= shift_result;
    end
  end

endmodule