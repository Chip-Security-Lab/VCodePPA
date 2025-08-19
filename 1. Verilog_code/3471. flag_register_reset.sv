module flag_register_reset(
  input clk, reset_n,
  input set_flag1, set_flag2, set_flag3,
  input clear_flag1, clear_flag2, clear_flag3,
  output reg [2:0] flags
);
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n)
      flags <= 3'b000;
    else begin
      if (set_flag1) flags[0] <= 1'b1;
      else if (clear_flag1) flags[0] <= 1'b0;
      
      if (set_flag2) flags[1] <= 1'b1;
      else if (clear_flag2) flags[1] <= 1'b0;
      
      if (set_flag3) flags[2] <= 1'b1;
      else if (clear_flag3) flags[2] <= 1'b0;
    end
  end
endmodule
