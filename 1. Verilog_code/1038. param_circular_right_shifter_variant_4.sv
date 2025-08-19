//SystemVerilog
module param_circular_right_shifter #(
  parameter WIDTH = 8
)(
  input [WIDTH-1:0] data,
  input [$clog2(WIDTH)-1:0] rotate,
  output [WIDTH-1:0] result
);
  // 7位运算版本，条件反相减法器算法实现减法
  function [6:0] conditional_invert_subtract_7bit;
    input [6:0] minuend;
    input [6:0] subtrahend;
    reg [6:0] subtrahend_inverted;
    reg carry_in;
    reg [7:0] sum;
    begin
      subtrahend_inverted = ~subtrahend;
      carry_in = 1'b1;
      sum = {1'b0, minuend} + {1'b0, subtrahend_inverted} + carry_in;
      conditional_invert_subtract_7bit = sum[6:0];
    end
  endfunction

  reg [WIDTH-1:0] shifted_data;
  integer i;
  reg [2:0] rotate_amount_7bit;
  reg [6:0] rotate_index_7bit;
  always @(*) begin
    shifted_data = data;
    rotate_amount_7bit = rotate[2:0];
    case (rotate_amount_7bit)
      3'd0: shifted_data = data;
      3'd1: shifted_data = {data[0], data[WIDTH-1:1]};
      3'd2: shifted_data = {data[1:0], data[WIDTH-1:2]};
      3'd3: shifted_data = {data[2:0], data[WIDTH-1:3]};
      3'd4: shifted_data = {data[3:0], data[WIDTH-1:4]};
      3'd5: shifted_data = {data[4:0], data[WIDTH-1:5]};
      3'd6: shifted_data = {data[5:0], data[WIDTH-1:6]};
      3'd7: begin
        // 使用条件反相减法器算法计算下标
        for (i = 0; i < WIDTH; i = i + 1) begin
          rotate_index_7bit = conditional_invert_subtract_7bit(i[6:0], 7'd7);
          shifted_data[i] = data[rotate_index_7bit];
        end
      end
      default: shifted_data = data;
    endcase
  end

  assign result = shifted_data;
endmodule