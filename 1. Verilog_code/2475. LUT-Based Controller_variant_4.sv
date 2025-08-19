//SystemVerilog
module lut_priority_intr_ctrl(
  input wire clk, rst_n,
  input wire [3:0] intr,
  input wire [3:0] config_sel,
  output reg [1:0] intr_id,
  output reg valid
);
  // Configuration lookup table
  reg [7:0] priority_lut [0:15];
  
  // Pipeline stage registers
  reg [3:0] intr_stage1;
  reg [3:0] config_sel_stage1;
  reg [7:0] selected_config_stage1;
  reg [7:0] selected_config_stage2;
  reg [3:0] intr_stage2;
  reg valid_stage1, valid_stage2;
  
  // Additional pipeline registers for critical path optimization
  reg [1:0] priority_check1, priority_check2;
  reg [1:0] priority_result1, priority_result2;
  reg has_interrupt1, has_interrupt2;
  reg [3:0] intr_stage3;
  reg [7:0] selected_config_stage3;
  reg valid_stage3;
  
  // Intermediate signals
  wire [7:0] selected_config;
  
  // LUT initialization
  initial begin
    priority_lut[0] = 8'h03_12; // 0,1,2,3 (standard)
    priority_lut[1] = 8'h30_21; // 3,0,2,1
    priority_lut[2] = 8'h12_03; // 1,2,0,3
    priority_lut[3] = 8'h21_30; // 2,1,3,0
    priority_lut[4] = 8'h01_23; // 0,1,2,3
    priority_lut[5] = 8'h23_01; // 2,3,0,1
    priority_lut[6] = 8'h10_32; // 1,0,3,2
    priority_lut[7] = 8'h32_10; // 3,2,1,0
    priority_lut[8] = 8'h02_13; // 0,2,1,3
    priority_lut[9] = 8'h13_02; // 1,3,0,2
    priority_lut[10] = 8'h31_20; // 3,1,2,0
    priority_lut[11] = 8'h20_31; // 2,0,3,1
    priority_lut[12] = 8'h03_21; // 0,3,2,1
    priority_lut[13] = 8'h21_03; // 2,1,0,3
    priority_lut[14] = 8'h30_12; // 3,0,1,2
    priority_lut[15] = 8'h12_30; // 1,2,3,0
  end
  
  // Stage 1: Capture inputs and lookup configuration
  assign selected_config = priority_lut[config_sel];
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      intr_stage1 <= 4'b0;
      config_sel_stage1 <= 4'b0;
      selected_config_stage1 <= 8'b0;
      valid_stage1 <= 1'b0;
    end else begin
      intr_stage1 <= intr;
      config_sel_stage1 <= config_sel;
      selected_config_stage1 <= selected_config;
      valid_stage1 <= |intr;
    end
  end
  
  // Stage 2: Determine priority and interrupt detection - first part
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      intr_stage2 <= 4'b0;
      selected_config_stage2 <= 8'b0;
      valid_stage2 <= 1'b0;
      // Clear first part of priority check
      priority_check1 <= 2'b0;
      priority_result1 <= 2'b0;
      has_interrupt1 <= 1'b0;
    end else begin
      intr_stage2 <= intr_stage1;
      selected_config_stage2 <= selected_config_stage1;
      valid_stage2 <= valid_stage1;
      
      // Check first two priorities (split the combinational logic)
      has_interrupt1 <= 1'b0;
      priority_result1 <= 2'b0;
      
      if (intr_stage1[selected_config_stage1[7:6]]) begin
        priority_result1 <= selected_config_stage1[7:6];
        has_interrupt1 <= 1'b1;
      end
      else if (intr_stage1[selected_config_stage1[5:4]]) begin
        priority_result1 <= selected_config_stage1[5:4];
        has_interrupt1 <= 1'b1;
      end
    end
  end
  
  // Stage 3: Determine priority and interrupt detection - second part
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      intr_stage3 <= 4'b0;
      selected_config_stage3 <= 8'b0;
      valid_stage3 <= 1'b0;
      priority_result2 <= 2'b0;
      has_interrupt2 <= 1'b0;
      priority_check2 <= 2'b0;
    end else begin
      intr_stage3 <= intr_stage2;
      selected_config_stage3 <= selected_config_stage2;
      valid_stage3 <= valid_stage2;
      
      // Keep first check results
      priority_check2 <= priority_result1;
      
      // If no interrupt found in first check, check second two priorities
      has_interrupt2 <= has_interrupt1;
      priority_result2 <= priority_result1;
      
      if (!has_interrupt1) begin
        if (intr_stage2[selected_config_stage2[3:2]]) begin
          priority_result2 <= selected_config_stage2[3:2];
          has_interrupt2 <= 1'b1;
        end
        else if (intr_stage2[selected_config_stage2[1:0]]) begin
          priority_result2 <= selected_config_stage2[1:0];
          has_interrupt2 <= 1'b1;
        end
      end
    end
  end
  
  // Output stage
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      intr_id <= 2'b0;
      valid <= 1'b0;
    end else begin
      intr_id <= priority_result2;
      valid <= valid_stage3 & has_interrupt2;
    end
  end
endmodule