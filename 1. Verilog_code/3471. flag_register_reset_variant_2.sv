//SystemVerilog
module flag_register_reset(
  input clk, reset_n,
  input set_flag1, set_flag2, set_flag3,
  input clear_flag1, clear_flag2, clear_flag3,
  output reg [2:0] flags
);
  
  wire [2:0] set_flags;
  wire [2:0] clear_flags;
  
  assign set_flags = {set_flag3, set_flag2, set_flag1};
  assign clear_flags = {clear_flag3, clear_flag2, clear_flag1};
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n)
      flags <= 3'b000;
    else begin
      for (int i = 0; i < 3; i = i + 1) begin
        if (set_flags[i])
          flags[i] <= 1'b1;
        else if (clear_flags[i])
          flags[i] <= 1'b0;
      end
    end
  end
  
endmodule