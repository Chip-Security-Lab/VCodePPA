//SystemVerilog
module reset_sync_en_sync(
  input  wire clk,
  input  wire en,
  input  wire rst_n,
  output reg  rst_sync
);
  // Pre-enable and post-enable registers for better timing
  reg  stage0_pre_en;
  reg  stage0;
  reg  stage1;
  
  // First stage register moved before enable logic
  always @(posedge clk) begin
    if(!rst_n) begin
      stage0_pre_en <= 1'b0;
    end else begin
      // First stage is always active regardless of enable
      stage0_pre_en <= 1'b1;
    end
  end
  
  // Second and third stage registers after enable logic
  always @(posedge clk) begin
    if(!rst_n) begin
      stage0   <= 1'b0;
      stage1   <= 1'b0;
      rst_sync <= 1'b0;
    end else begin
      if(en) begin
        stage0   <= stage0_pre_en;
        stage1   <= stage0;
        rst_sync <= stage1;
      end
    end
  end
endmodule