module lut_priority_intr_ctrl(
  input clk, rst_n,
  input [3:0] intr,
  input [3:0] config_sel,
  output reg [1:0] intr_id,
  output reg valid
);
  // 16 different priority configurations
  reg [7:0] priority_lut [0:15];
  wire [7:0] selected_config;
  
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
  
  assign selected_config = priority_lut[config_sel];
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      intr_id <= 2'b0; valid <= 1'b0;
    end else begin
      valid <= |intr;
      if (intr[selected_config[7:6]]) intr_id <= selected_config[7:6];
      else if (intr[selected_config[5:4]]) intr_id <= selected_config[5:4];
      else if (intr[selected_config[3:2]]) intr_id <= selected_config[3:2];
      else if (intr[selected_config[1:0]]) intr_id <= selected_config[1:0];
    end
  end
endmodule