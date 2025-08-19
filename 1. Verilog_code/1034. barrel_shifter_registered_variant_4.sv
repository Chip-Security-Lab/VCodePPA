//SystemVerilog
module barrel_shifter_registered (
  input wire clk,
  input wire enable,
  input wire [15:0] data,
  input wire [3:0] shift,
  input wire direction, // 0=right, 1=left
  output reg [15:0] shifted_data
);

  wire [15:0] left_stage1, left_stage2, left_stage3, left_stage4;
  wire [15:0] right_stage1, right_stage2, right_stage3, right_stage4;
  wire [15:0] left_shifted, right_shifted;
  wire [15:0] mux_shifted;

  // Left shift stages (barrel shifter using MUXes)
  assign left_stage1  = shift[0] ? {data[14:0], 1'b0}         : data;
  assign left_stage2  = shift[1] ? {left_stage1[13:0], 2'b00} : left_stage1;
  assign left_stage3  = shift[2] ? {left_stage2[11:0], 4'b0000} : left_stage2;
  assign left_stage4  = shift[3] ? {left_stage3[7:0], 8'b00000000} : left_stage3;
  assign left_shifted = left_stage4;

  // Right shift stages (barrel shifter using MUXes)
  assign right_stage1  = shift[0] ? {1'b0, data[15:1]}         : data;
  assign right_stage2  = shift[1] ? {2'b00, right_stage1[15:2]} : right_stage1;
  assign right_stage3  = shift[2] ? {4'b0000, right_stage2[15:4]} : right_stage2;
  assign right_stage4  = shift[3] ? {8'b00000000, right_stage3[15:8]} : right_stage3;
  assign right_shifted = right_stage4;

  // Select between left and right shift
  assign mux_shifted = direction ? left_shifted : right_shifted;

  // Register the output
  always @(posedge clk) begin
    if (enable) begin
      shifted_data <= mux_shifted;
    end
  end

endmodule