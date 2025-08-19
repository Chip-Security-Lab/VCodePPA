//SystemVerilog
//-----------------------------------------------------------------------------
// Top-level Module - Pipelined Interrupt Controller with Selectable Priority
//-----------------------------------------------------------------------------
module lut_priority_intr_ctrl (
  input wire clk,
  input wire rst_n,
  input wire [3:0] intr,
  input wire [3:0] config_sel,
  output wire [1:0] intr_id,
  output wire valid
);
  // Pipeline control signals
  wire valid_stage1, valid_stage2;
  
  // Internal signals for connecting sub-modules
  wire [7:0] selected_config;
  wire [7:0] selected_config_stage1;
  wire [3:0] intr_stage1;
  
  // Stage 1: LUT lookup and register input signals
  priority_config_lut priority_config (
    .config_sel(config_sel),
    .selected_config(selected_config)
  );
  
  // Pipeline registers for stage 1
  dff_stage1 stage1_regs (
    .clk(clk),
    .rst_n(rst_n),
    .intr_in(intr),
    .config_in(selected_config),
    .valid_in(|intr),
    .intr_out(intr_stage1),
    .config_out(selected_config_stage1),
    .valid_out(valid_stage1)
  );
  
  // Stage 2: Priority encoding
  priority_encoder encoder (
    .clk(clk),
    .rst_n(rst_n),
    .intr(intr_stage1),
    .selected_config(selected_config_stage1),
    .valid_in(valid_stage1),
    .intr_id(intr_id),
    .valid(valid)
  );
  
endmodule

//-----------------------------------------------------------------------------
// Stage 1 Pipeline Registers
//-----------------------------------------------------------------------------
module dff_stage1 (
  input wire clk,
  input wire rst_n,
  input wire [3:0] intr_in,
  input wire [7:0] config_in,
  input wire valid_in,
  output reg [3:0] intr_out,
  output reg [7:0] config_out,
  output reg valid_out
);
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      intr_out <= 4'b0;
      config_out <= 8'b0;
      valid_out <= 1'b0;
    end else begin
      intr_out <= intr_in;
      config_out <= config_in;
      valid_out <= valid_in;
    end
  end
  
endmodule

//-----------------------------------------------------------------------------
// Priority Configuration Lookup Table - Stores and selects priority modes
//-----------------------------------------------------------------------------
module priority_config_lut (
  input wire [3:0] config_sel,
  output wire [7:0] selected_config
);
  // 16 different priority configurations memory
  reg [7:0] priority_lut [0:15];
  
  // Initialize the lookup table with different priority configurations
  initial begin
    priority_lut[0]  = 8'h03_12; // 0,1,2,3 (standard)
    priority_lut[1]  = 8'h30_21; // 3,0,2,1
    priority_lut[2]  = 8'h12_03; // 1,2,0,3
    priority_lut[3]  = 8'h21_30; // 2,1,3,0
    priority_lut[4]  = 8'h01_23; // 0,1,2,3
    priority_lut[5]  = 8'h23_01; // 2,3,0,1
    priority_lut[6]  = 8'h10_32; // 1,0,3,2
    priority_lut[7]  = 8'h32_10; // 3,2,1,0
    priority_lut[8]  = 8'h02_13; // 0,2,1,3
    priority_lut[9]  = 8'h13_02; // 1,3,0,2
    priority_lut[10] = 8'h31_20; // 3,1,2,0
    priority_lut[11] = 8'h20_31; // 2,0,3,1
    priority_lut[12] = 8'h03_21; // 0,3,2,1
    priority_lut[13] = 8'h21_03; // 2,1,0,3
    priority_lut[14] = 8'h30_12; // 3,0,1,2
    priority_lut[15] = 8'h12_30; // 1,2,3,0
  end
  
  // Select the configuration based on config_sel
  assign selected_config = priority_lut[config_sel];
  
endmodule

//-----------------------------------------------------------------------------
// Priority Encoder - Pipeline Stage 2 with early priority extraction
//-----------------------------------------------------------------------------
module priority_encoder (
  input wire clk,
  input wire rst_n,
  input wire [3:0] intr,
  input wire [7:0] selected_config,
  input wire valid_in,
  output reg [1:0] intr_id,
  output reg valid
);
  // Extract priority levels from configuration
  wire [1:0] priority_level_0;
  wire [1:0] priority_level_1;
  wire [1:0] priority_level_2;
  wire [1:0] priority_level_3;
  
  // Intermediate priority evaluation signals
  wire [3:0] priority_match;
  wire [1:0] priority_id_stage2a;
  reg [1:0] priority_id_stage2b;
  reg valid_stage2a, valid_stage2b;

  // Assign priority levels from configuration byte
  assign priority_level_0 = selected_config[7:6];
  assign priority_level_1 = selected_config[5:4];
  assign priority_level_2 = selected_config[3:2];
  assign priority_level_3 = selected_config[1:0];
  
  // Match interrupts with their assigned priority levels
  assign priority_match[0] = intr[priority_level_0];
  assign priority_match[1] = intr[priority_level_1];
  assign priority_match[2] = intr[priority_level_2];
  assign priority_match[3] = intr[priority_level_3];
  
  // First-level priority evaluation (combinational)
  assign priority_id_stage2a = priority_match[0] ? priority_level_0 :
                              priority_match[1] ? priority_level_1 :
                              priority_match[2] ? priority_level_2 :
                              priority_level_3;
  
  // Pipeline stage 2a to 2b
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      priority_id_stage2b <= 2'b00;
      valid_stage2a <= 1'b0;
    end else begin
      priority_id_stage2b <= priority_id_stage2a;
      valid_stage2a <= valid_in & |priority_match;
    end
  end
  
  // Final stage output
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      intr_id <= 2'b00;
      valid <= 1'b0;
      valid_stage2b <= 1'b0;
    end else begin
      intr_id <= priority_id_stage2b;
      valid_stage2b <= valid_stage2a;
      valid <= valid_stage2b;
    end
  end
  
endmodule