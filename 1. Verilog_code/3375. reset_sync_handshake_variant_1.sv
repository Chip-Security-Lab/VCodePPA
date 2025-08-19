//SystemVerilog
//IEEE 1364-2005 Verilog
module reset_sync_handshake(
  input  wire clk,
  input  wire rst_n,
  input  wire rst_valid,
  output reg  rst_done
);
  // 使用两级触发器结构提高亚稳态恢复能力
  reg sync_flop1, sync_flop2;
  
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      // 复位时清零所有触发器
      sync_flop1 <= 1'b0;
      sync_flop2 <= 1'b0;
      rst_done   <= 1'b0;
    end else if(rst_valid) begin
      // 当复位有效且rst_valid为高时，设置第一级触发器
      sync_flop1 <= 1'b1;
      sync_flop2 <= sync_flop1;
      rst_done   <= sync_flop2;
    end else begin
      // 正常同步操作，未检测到复位请求
      sync_flop1 <= 1'b0; 
      sync_flop2 <= sync_flop1;
      rst_done   <= sync_flop2;
    end
  end
endmodule