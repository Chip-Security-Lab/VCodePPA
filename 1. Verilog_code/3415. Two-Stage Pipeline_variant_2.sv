//SystemVerilog
module RD5 #(parameter W=8)(
  input wire clk,
  input wire rst,
  input wire en,
  input wire [W-1:0] din,
  output reg [W-1:0] dout,
  output wire valid_out,
  input wire ready_in,
  output wire ready_out
);
  
  // Pipeline stage registers with data processing at each stage
  reg [W-1:0] stage1_reg, stage2_reg, stage3_reg, stage4_reg;
  
  // Pipeline valid and ready signals
  reg valid_stage1, valid_stage2, valid_stage3, valid_stage4;
  wire ready_stage1, ready_stage2, ready_stage3, ready_stage4;
  
  // Pipeline stall control
  assign ready_stage4 = ready_in;
  assign ready_stage3 = valid_stage4 ? ready_stage4 : 1'b1;
  assign ready_stage2 = valid_stage3 ? ready_stage3 : 1'b1;
  assign ready_stage1 = valid_stage2 ? ready_stage2 : 1'b1;
  assign ready_out = valid_stage1 ? ready_stage1 : 1'b1;
  
  // Output valid signal
  assign valid_out = valid_stage4;
  
  // Process data at each stage with meaningful transformations
  wire [W-1:0] stage1_data, stage2_data, stage3_data, stage4_data;
  
  // Stage 1 processing - bit reverse
  genvar i;
  generate
    for (i = 0; i < W; i = i + 1) begin : GEN_STAGE1
      assign stage1_data[i] = din[W-1-i];
    end
  endgenerate
  
  // Stage 2 processing - XOR with stage number
  assign stage2_data = stage1_reg ^ {W{1'b0}} + 8'h1;
  
  // Stage 3 processing - shift left by 1
  assign stage3_data = {stage2_reg[W-2:0], stage2_reg[W-1]};
  
  // Stage 4 processing - add constant
  assign stage4_data = stage3_reg + 8'h5;
  
  // Pipeline control logic
  always @(posedge clk) begin
    if (rst) begin
      // Reset all pipeline stages
      stage1_reg <= {W{1'b0}};
      stage2_reg <= {W{1'b0}};
      stage3_reg <= {W{1'b0}};
      stage4_reg <= {W{1'b0}};
      dout <= {W{1'b0}};
      
      // Reset valid signals
      valid_stage1 <= 1'b0;
      valid_stage2 <= 1'b0;
      valid_stage3 <= 1'b0;
      valid_stage4 <= 1'b0;
    end
    else begin
      // Pipeline data path with ready/valid handshaking
      
      // Stage 1 - Input stage
      if (en && ready_out) begin
        stage1_reg <= stage1_data;
        valid_stage1 <= 1'b1;
      end
      else if (ready_stage1) begin
        valid_stage1 <= 1'b0;
      end
      
      // Stage 2
      if (ready_stage1 && valid_stage1) begin
        stage2_reg <= stage2_data;
        valid_stage2 <= 1'b1;
      end
      else if (ready_stage2) begin
        valid_stage2 <= valid_stage1;
      end
      
      // Stage 3
      if (ready_stage2 && valid_stage2) begin
        stage3_reg <= stage3_data;
        valid_stage3 <= 1'b1;
      end
      else if (ready_stage3) begin
        valid_stage3 <= valid_stage2;
      end
      
      // Stage 4
      if (ready_stage3 && valid_stage3) begin
        stage4_reg <= stage4_data;
        valid_stage4 <= 1'b1;
      end
      else if (ready_stage4) begin
        valid_stage4 <= valid_stage3;
      end
      
      // Output stage
      if (valid_stage4 && ready_in) begin
        dout <= stage4_reg;
      end
    end
  end
  
endmodule