//SystemVerilog
module async_logical_right_shifter #(
  parameter DATA_WIDTH = 16,
  parameter SHIFT_WIDTH = 4
)(
  input  [DATA_WIDTH-1:0] in_data,
  input  [SHIFT_WIDTH-1:0] shift_amount,
  output [DATA_WIDTH-1:0] out_data
);

  wire [DATA_WIDTH-1:0] shifted_output;
  wire [SHIFT_WIDTH:0]  index_sum;
  wire [SHIFT_WIDTH:0]  index_b_complement;
  wire                  index_carry_out;
  wire [DATA_WIDTH-1:0] valid_mask;

  genvar bit_idx;
  generate
    for (bit_idx = 0; bit_idx < DATA_WIDTH; bit_idx = bit_idx + 1) begin : gen_right_shift_logic
      wire [SHIFT_WIDTH:0] index_a;
      wire [SHIFT_WIDTH:0] index_b;
      wire [SHIFT_WIDTH:0] index_b_inv;
      wire [SHIFT_WIDTH:0] index_result;
      wire                 index_carry;
      wire                 index_is_valid;

      // Prepare operands for two's complement subtraction: index = bit_idx - shift_amount
      assign index_a = {1'b0, bit_idx[SHIFT_WIDTH-1:0]};
      assign index_b = {1'b0, shift_amount};

      // Two's complement: invert index_b and add 1
      assign index_b_inv = ~index_b;
      assign {index_carry, index_result} = index_a + index_b_inv + 1'b1;

      // Check if index_result is within range [0, DATA_WIDTH-1]
      assign index_is_valid = (index_result < DATA_WIDTH);

      // Mask for valid index
      assign valid_mask[bit_idx] = index_is_valid;

      // Assign output bit using two's complement subtraction result
      assign shifted_output[bit_idx] = index_is_valid ? in_data[index_result[SHIFT_WIDTH-1:0]] : 1'b0;
    end
  endgenerate

  assign out_data = shifted_output;

endmodule