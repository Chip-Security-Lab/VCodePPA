//SystemVerilog
module flag_register_reset(
  input clk, reset_n,
  input set_flag1, set_flag2, set_flag3,
  input clear_flag1, clear_flag2, clear_flag3,
  output [2:0] flags
);
  reg [2:0] flags_internal;
  reg [2:0] flags_buf1;
  reg [2:0] flags_buf2;
  
  // Registered control signals to reduce combinational path
  reg set_flag1_r, set_flag2_r, set_flag3_r;
  reg clear_flag1_r, clear_flag2_r, clear_flag3_r;
  
  // Register control signals to break long combinational paths
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      set_flag1_r <= 1'b0;
      set_flag2_r <= 1'b0;
      set_flag3_r <= 1'b0;
      clear_flag1_r <= 1'b0;
      clear_flag2_r <= 1'b0;
      clear_flag3_r <= 1'b0;
    end
    else begin
      set_flag1_r <= set_flag1;
      set_flag2_r <= set_flag2;
      set_flag3_r <= set_flag3;
      clear_flag1_r <= clear_flag1;
      clear_flag2_r <= clear_flag2;
      clear_flag3_r <= clear_flag3;
    end
  end
  
  // Primary flag register logic - now using registered control signals
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n)
      flags_internal <= 3'b000;
    else begin
      if (set_flag1_r) flags_internal[0] <= 1'b1;
      else if (clear_flag1_r) flags_internal[0] <= 1'b0;
      
      if (set_flag2_r) flags_internal[1] <= 1'b1;
      else if (clear_flag2_r) flags_internal[1] <= 1'b0;
      
      if (set_flag3_r) flags_internal[2] <= 1'b1;
      else if (clear_flag3_r) flags_internal[2] <= 1'b0;
    end
  end
  
  // First level buffer register
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n)
      flags_buf1 <= 3'b000;
    else
      flags_buf1 <= flags_internal;
  end
  
  // Second level buffer register
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n)
      flags_buf2 <= 3'b000;
    else
      flags_buf2 <= flags_buf1;
  end
  
  // Assign output through buffer to distribute fanout load
  assign flags = flags_buf2;
  
endmodule