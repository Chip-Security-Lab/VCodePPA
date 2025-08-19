//SystemVerilog
module flag_register_reset(
  input  wire       clk,
  input  wire       reset_n,
  input  wire       valid_flag1,
  input  wire       valid_flag2, 
  input  wire       valid_flag3,
  input  wire       clear_valid_flag1, 
  input  wire       clear_valid_flag2, 
  input  wire       clear_valid_flag3,
  output wire       ready_flag1,
  output wire       ready_flag2,
  output wire       ready_flag3,
  output reg  [2:0] flags
);

  // Pipeline stage registers
  reg valid_flag1_stage1, valid_flag2_stage1, valid_flag3_stage1;
  reg clear_flag1_stage1, clear_flag2_stage1, clear_flag3_stage1;
  
  reg valid_flag1_stage2, valid_flag2_stage2, valid_flag3_stage2;
  reg clear_flag1_stage2, clear_flag2_stage2, clear_flag3_stage2;
  
  // Pipeline control signals
  reg valid_stage1, valid_stage2;
  reg ready_stage1, ready_stage2, ready_stage3;
  
  // Ready propagation (backpressure handling)
  assign ready_flag1 = ready_stage1;
  assign ready_flag2 = ready_stage1;
  assign ready_flag3 = ready_stage1;
  
  // Stage 3 is always ready to receive results from stage 2
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n)
      ready_stage3 <= 1'b1;
    else
      ready_stage3 <= 1'b1;
  end
  
  // Stage 2 is ready when stage 3 is ready
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n)
      ready_stage2 <= 1'b1;
    else
      ready_stage2 <= ready_stage3;
  end
  
  // Stage 1 is ready when stage 2 is ready
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n)
      ready_stage1 <= 1'b1;
    else
      ready_stage1 <= ready_stage2;
  end
  
  // Pipeline Stage 1: Register inputs
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      valid_flag1_stage1 <= 1'b0;
      valid_flag2_stage1 <= 1'b0;
      valid_flag3_stage1 <= 1'b0;
      clear_flag1_stage1 <= 1'b0;
      clear_flag2_stage1 <= 1'b0;
      clear_flag3_stage1 <= 1'b0;
      valid_stage1 <= 1'b0;
    end
    else if (ready_stage1) begin
      valid_flag1_stage1 <= valid_flag1;
      valid_flag2_stage1 <= valid_flag2;
      valid_flag3_stage1 <= valid_flag3;
      clear_flag1_stage1 <= clear_valid_flag1;
      clear_flag2_stage1 <= clear_valid_flag2;
      clear_flag3_stage1 <= clear_valid_flag3;
      valid_stage1 <= (valid_flag1 || valid_flag2 || valid_flag3 || 
                      clear_valid_flag1 || clear_valid_flag2 || clear_valid_flag3);
    end
  end
  
  // Pipeline Stage 2: Process flag operations
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      valid_flag1_stage2 <= 1'b0;
      valid_flag2_stage2 <= 1'b0;
      valid_flag3_stage2 <= 1'b0;
      clear_flag1_stage2 <= 1'b0;
      clear_flag2_stage2 <= 1'b0;
      clear_flag3_stage2 <= 1'b0;
      valid_stage2 <= 1'b0;
    end
    else if (ready_stage2) begin
      valid_flag1_stage2 <= valid_flag1_stage1;
      valid_flag2_stage2 <= valid_flag2_stage1;
      valid_flag3_stage2 <= valid_flag3_stage1;
      clear_flag1_stage2 <= clear_flag1_stage1;
      clear_flag2_stage2 <= clear_flag2_stage1;
      clear_flag3_stage2 <= clear_flag3_stage1;
      valid_stage2 <= valid_stage1;
    end
  end
  
  // Pipeline Stage 3: Update flags register
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      flags <= 3'b000;
    end
    else if (valid_stage2 && ready_stage3) begin
      // Flag 1 processing
      if (valid_flag1_stage2) 
        flags[0] <= 1'b1;
      else if (clear_flag1_stage2) 
        flags[0] <= 1'b0;
      
      // Flag 2 processing
      if (valid_flag2_stage2) 
        flags[1] <= 1'b1;
      else if (clear_flag2_stage2) 
        flags[1] <= 1'b0;
      
      // Flag 3 processing
      if (valid_flag3_stage2) 
        flags[2] <= 1'b1;
      else if (clear_flag3_stage2) 
        flags[2] <= 1'b0;
    end
  end
  
endmodule