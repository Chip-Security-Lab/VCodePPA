//SystemVerilog
module pipelined_intr_ctrl(
  input clk, rst_n,
  input [15:0] intr_req,
  output reg [3:0] intr_id,
  output reg valid
);
  // Pipeline registers
  reg [15:0] stage1_req;
  reg [15:0] stage2_req;
  reg [15:0] stage3_req_upper;
  reg [15:0] stage3_req_lower;
  reg stage3_upper_valid, stage3_lower_valid;
  reg [3:0] stage4_id_upper, stage4_id_lower;
  reg stage4_valid_upper, stage4_valid_lower;
  reg [3:0] stage5_id;
  reg stage5_valid;
  reg [3:0] highest_pri_id_upper, highest_pri_id_lower;
  
  //====================================================
  // Pipeline stage 1: Register input requests
  //====================================================
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      stage1_req <= 16'h0;
    else
      stage1_req <= intr_req;
  end
  
  //====================================================
  // Pipeline stage 2: Additional request buffering
  //====================================================
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      stage2_req <= 16'h0;
    else
      stage2_req <= stage1_req;
  end
  
  //====================================================
  // Pipeline stage 3: Split request processing
  //====================================================
  
  // Extract upper bits (15:8) and validate
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      stage3_req_upper <= 8'h0;
      stage3_upper_valid <= 1'b0;
    end else begin
      stage3_req_upper <= stage2_req[15:8];
      stage3_upper_valid <= |stage2_req[15:8];
    end
  end
  
  // Extract lower bits (7:0) and validate
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      stage3_req_lower <= 8'h0;
      stage3_lower_valid <= 1'b0;
    end else begin
      stage3_req_lower <= stage2_req[7:0];
      stage3_lower_valid <= |stage2_req[7:0];
    end
  end
  
  //====================================================
  // Priority encoders (combinational logic)
  //====================================================
  
  // Upper 8 bits priority encoder
  always @(*) begin
    casez (stage3_req_upper)
      8'b1???????: highest_pri_id_upper = 4'd15;
      8'b01??????: highest_pri_id_upper = 4'd14;
      8'b001?????: highest_pri_id_upper = 4'd13;
      8'b0001????: highest_pri_id_upper = 4'd12;
      8'b00001???: highest_pri_id_upper = 4'd11;
      8'b000001??: highest_pri_id_upper = 4'd10;
      8'b0000001?: highest_pri_id_upper = 4'd9;
      8'b00000001: highest_pri_id_upper = 4'd8;
      default:     highest_pri_id_upper = 4'd0;
    endcase
  end
  
  // Lower 8 bits priority encoder
  always @(*) begin
    casez (stage3_req_lower)
      8'b1???????: highest_pri_id_lower = 4'd7;
      8'b01??????: highest_pri_id_lower = 4'd6;
      8'b001?????: highest_pri_id_lower = 4'd5;
      8'b0001????: highest_pri_id_lower = 4'd4;
      8'b00001???: highest_pri_id_lower = 4'd3;
      8'b000001??: highest_pri_id_lower = 4'd2;
      8'b0000001?: highest_pri_id_lower = 4'd1;
      8'b00000001: highest_pri_id_lower = 4'd0;
      default:     highest_pri_id_lower = 4'd0;
    endcase
  end
  
  //====================================================
  // Pipeline stage 4: Register encoded priorities
  //====================================================
  
  // Register upper half priority results
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      stage4_id_upper <= 4'h0;
      stage4_valid_upper <= 1'b0;
    end else begin
      stage4_id_upper <= highest_pri_id_upper;
      stage4_valid_upper <= stage3_upper_valid;
    end
  end
  
  // Register lower half priority results
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      stage4_id_lower <= 4'h0;
      stage4_valid_lower <= 1'b0;
    end else begin
      stage4_id_lower <= highest_pri_id_lower;
      stage4_valid_lower <= stage3_lower_valid;
    end
  end
  
  //====================================================
  // Pipeline stage 5: Merge results with priority selection
  //====================================================
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      stage5_id <= 4'h0;
      stage5_valid <= 1'b0;
    end else begin
      // If upper half has valid interrupt, it takes priority
      if (stage4_valid_upper) begin
        stage5_id <= stage4_id_upper;
        stage5_valid <= 1'b1;
      end else begin
        stage5_id <= stage4_id_lower;
        stage5_valid <= stage4_valid_lower;
      end
    end
  end
  
  //====================================================
  // Pipeline stage 6: Final output
  //====================================================
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      intr_id <= 4'h0;
      valid <= 1'b0;
    end else begin
      intr_id <= stage5_id;
      valid <= stage5_valid;
    end
  end
endmodule