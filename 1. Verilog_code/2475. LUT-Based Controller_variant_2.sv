//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// File: lut_priority_intr_ctrl.v
// Description: Hierarchical interrupt controller with configurable priorities
///////////////////////////////////////////////////////////////////////////////

module lut_priority_intr_ctrl (
  input            clk,
  input            rst_n,
  input      [3:0] intr,
  input      [3:0] config_sel,
  output reg [1:0] intr_id,
  output reg       valid
);

  wire [7:0] selected_config;

  // Instantiate priority configuration module
  priority_config_storage priority_cfg_inst (
    .config_sel      (config_sel),
    .selected_config (selected_config)
  );

  // Instantiate priority resolver module
  priority_resolver resolver_inst (
    .clk             (clk),
    .rst_n           (rst_n),
    .intr            (intr),
    .selected_config (selected_config),
    .intr_id         (intr_id),
    .valid           (valid)
  );

endmodule

///////////////////////////////////////////////////////////////////////////////
// Priority Configuration Storage Module
///////////////////////////////////////////////////////////////////////////////
module priority_config_storage (
  input      [3:0] config_sel,
  output reg [7:0] selected_config
);

  // Priority configuration lookup implementation with case statement
  // to improve synthesis results compared to memory implementation
  always @(*) begin
    case (config_sel)
      4'h0:    selected_config = 8'h03_12; // 0,1,2,3 (standard)
      4'h1:    selected_config = 8'h30_21; // 3,0,2,1
      4'h2:    selected_config = 8'h12_03; // 1,2,0,3
      4'h3:    selected_config = 8'h21_30; // 2,1,3,0
      4'h4:    selected_config = 8'h01_23; // 0,1,2,3
      4'h5:    selected_config = 8'h23_01; // 2,3,0,1
      4'h6:    selected_config = 8'h10_32; // 1,0,3,2
      4'h7:    selected_config = 8'h32_10; // 3,2,1,0
      4'h8:    selected_config = 8'h02_13; // 0,2,1,3
      4'h9:    selected_config = 8'h13_02; // 1,3,0,2
      4'hA:    selected_config = 8'h31_20; // 3,1,2,0
      4'hB:    selected_config = 8'h20_31; // 2,0,3,1
      4'hC:    selected_config = 8'h03_21; // 0,3,2,1
      4'hD:    selected_config = 8'h21_03; // 2,1,0,3
      4'hE:    selected_config = 8'h30_12; // 3,0,1,2
      4'hF:    selected_config = 8'h12_30; // 1,2,3,0
      default: selected_config = 8'h03_12; // Default to standard priority
    endcase
  end

endmodule

///////////////////////////////////////////////////////////////////////////////
// Priority Resolver Module
///////////////////////////////////////////////////////////////////////////////
module priority_resolver (
  input            clk,
  input            rst_n,
  input      [3:0] intr,
  input      [7:0] selected_config,
  output reg [1:0] intr_id,
  output reg       valid
);

  // Extract priority levels from configuration
  wire [1:0] priority_level1 = selected_config[7:6];
  wire [1:0] priority_level2 = selected_config[5:4];
  wire [1:0] priority_level3 = selected_config[3:2];
  wire [1:0] priority_level4 = selected_config[1:0];
  
  // Pre-compute interrupt presence for each priority level
  reg intr_at_level1, intr_at_level2, intr_at_level3, intr_at_level4;
  reg [1:0] resolved_id;
  reg any_intr;
  
  // Priority resolution logic moved to combinational block
  // to reduce critical path in sequential logic
  always @(*) begin
    // Check if interrupts exist at each priority level
    intr_at_level1 = intr[priority_level1];
    intr_at_level2 = intr[priority_level2];
    intr_at_level3 = intr[priority_level3];
    intr_at_level4 = intr[priority_level4];
    
    // Detect if any interrupt is active (balanced tree reduction)
    any_intr = (intr_at_level1 | intr_at_level2) | (intr_at_level3 | intr_at_level4);
    
    // Parallel priority encoder implementation to balance paths
    if (intr_at_level1) begin
      resolved_id = priority_level1;
    end
    else if (intr_at_level2) begin
      resolved_id = priority_level2;
    end
    else if (intr_at_level3) begin
      resolved_id = priority_level3;
    end
    else begin
      resolved_id = priority_level4;
    end
  end
  
  // Register outputs with clean reset logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      intr_id <= 2'b0;
      valid   <= 1'b0;
    end 
    else begin
      valid   <= any_intr;
      intr_id <= resolved_id;
    end
  end

endmodule