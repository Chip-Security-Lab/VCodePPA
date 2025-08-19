//SystemVerilog
module reset_sync_enable(
  input  wire clk,
  input  wire en,
  input  wire rst_n,
  output reg  sync_reset
);
  reg flop1_stage1;
  reg flop2_stage2;
  reg flop3_stage3;
  reg flop4_stage4;
  
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      flop1_stage1 <= 1'b0;
      flop2_stage2 <= 1'b0;
      flop3_stage3 <= 1'b0;
      flop4_stage4 <= 1'b0;
      sync_reset <= 1'b0;
    end else if(en) begin
      flop1_stage1 <= 1'b1;
      flop2_stage2 <= flop1_stage1;
      flop3_stage3 <= flop2_stage2;
      flop4_stage4 <= flop3_stage3;
      sync_reset <= flop4_stage4;
    end
  end
endmodule