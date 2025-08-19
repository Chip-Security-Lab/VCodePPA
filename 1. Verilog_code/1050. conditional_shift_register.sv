module conditional_shift_register #(parameter WIDTH=8) (
  input clk, reset,
  input [WIDTH-1:0] parallel_in,
  input shift_in_bit,
  input [1:0] mode, // 00=hold, 01=load, 10=shift right, 11=shift left
  input condition,  // Only perform operation if condition is true
  output reg [WIDTH-1:0] parallel_out,
  output shift_out_bit
);
  always @(posedge clk or posedge reset) begin
    if (reset)
      parallel_out <= {WIDTH{1'b0}};
    else if (condition) begin
      case (mode)
        2'b01: parallel_out <= parallel_in;
        2'b10: parallel_out <= {shift_in_bit, parallel_out[WIDTH-1:1]};
        2'b11: parallel_out <= {parallel_out[WIDTH-2:0], shift_in_bit};
        default: parallel_out <= parallel_out; // Hold
      endcase
    end
  end
  
  // Shift out bit depends on shift direction
  assign shift_out_bit = (mode == 2'b10) ? parallel_out[0] : parallel_out[WIDTH-1];
endmodule