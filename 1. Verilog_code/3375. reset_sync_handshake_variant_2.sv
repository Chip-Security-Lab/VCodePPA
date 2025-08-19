//SystemVerilog
module reset_sync_handshake(
  input  wire clk,
  input  wire rst_n,
  input  wire rst_valid,
  output reg  rst_done
);
  // Expanded pipeline registers
  reg rst_valid_stage1;
  reg rst_valid_stage2;
  reg rst_valid_stage3;
  reg rst_valid_stage4;
  
  // Intermediate handshake signals
  reg handshake_stage1;
  reg handshake_stage2;
  
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      // Reset all pipeline stages
      rst_valid_stage1 <= 1'b0;
      rst_valid_stage2 <= 1'b0;
      rst_valid_stage3 <= 1'b0;
      rst_valid_stage4 <= 1'b0;
      handshake_stage1 <= 1'b0;
      handshake_stage2 <= 1'b0;
      rst_done <= 1'b0;
    end else begin
      // Enhanced pipeline with more stages for better timing
      rst_valid_stage1 <= rst_valid;
      rst_valid_stage2 <= rst_valid_stage1;
      rst_valid_stage3 <= rst_valid_stage2;
      rst_valid_stage4 <= rst_valid_stage3;
      
      // Handshaking logic split into multiple stages
      handshake_stage1 <= rst_valid_stage3 && rst_valid_stage4;
      handshake_stage2 <= handshake_stage1;
      rst_done <= handshake_stage2;
    end
  end
endmodule