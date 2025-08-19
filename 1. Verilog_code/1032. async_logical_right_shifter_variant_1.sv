//SystemVerilog
module async_logical_right_shifter #(
  parameter DATA_WIDTH = 16,
  parameter SHIFT_WIDTH = 4
)(
  input  [DATA_WIDTH-1:0] in_data,
  input  [SHIFT_WIDTH-1:0] shift_amount,
  output [DATA_WIDTH-1:0] out_data
);
  wire [DATA_WIDTH-1:0] stage [0:SHIFT_WIDTH];

  assign stage[0] = in_data;

  genvar i;
  generate
    for (i = 0; i < SHIFT_WIDTH; i = i + 1) begin : shift_stage_gen
      wire [DATA_WIDTH-1:0] shifted_value;
      wire [DATA_WIDTH-1:0] selected_subtrahend;
      wire [DATA_WIDTH-1:0] subtrahend_complement;
      wire [DATA_WIDTH-1:0] subtraction_result;
      wire [DATA_WIDTH-1:0] mux_output;

      // Shift right by 2^i bits, fill with zeros
      assign shifted_value = { { (1<<i) {1'b0} }, stage[i][DATA_WIDTH-1:(1<<i)] };

      // Use stage[i] as minuend, shifted_value as subtrahend
      // Two's complement of shifted_value: ~shifted_value + 1
      assign subtrahend_complement = ~shifted_value + 16'd1;

      // If shift_amount[i] is 1, subtract shifted_value from stage[i] using two's complement addition
      assign subtraction_result = stage[i] + subtrahend_complement;

      // Select subtraction result or keep original value
      assign mux_output = shift_amount[i] ? subtraction_result : stage[i];

      assign stage[i+1] = mux_output;
    end
  endgenerate

  assign out_data = stage[SHIFT_WIDTH];
endmodule