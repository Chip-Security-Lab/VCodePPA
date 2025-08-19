//SystemVerilog
//IEEE 1364-2005
module flag_register_reset(
  input clk, reset_n,
  input set_flag1, set_flag2, set_flag3,
  input clear_flag1, clear_flag2, clear_flag3,
  output [2:0] flags
);
  // Direct flags output register
  reg [2:0] flags_r;
  // Intermediate control signals
  wire [2:0] set_flags, clear_flags;
  wire [2:0] next_flags;
  
  // Create packed arrays for more efficient handling
  assign set_flags = {set_flag3, set_flag2, set_flag1};
  assign clear_flags = {clear_flag3, clear_flag2, clear_flag1};
  
  // Calculate next flag values using parallel operations
  // Priority: reset_n > set > clear > keep current
  assign next_flags[0] = set_flags[0] ? 1'b1 : (clear_flags[0] ? 1'b0 : flags_r[0]);
  assign next_flags[1] = set_flags[1] ? 1'b1 : (clear_flags[1] ? 1'b0 : flags_r[1]);
  assign next_flags[2] = set_flags[2] ? 1'b1 : (clear_flags[2] ? 1'b0 : flags_r[2]);
  
  // Single always block for flag register updates
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n)
      flags_r <= 3'b000;
    else
      flags_r <= next_flags;
  end
  
  // Direct output assignment
  assign flags = flags_r;
  
endmodule