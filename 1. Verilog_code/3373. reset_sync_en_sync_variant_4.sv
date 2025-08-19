//SystemVerilog
module reset_sync_en_sync(
  input  wire clk,
  input  wire en,
  input  wire rst_n,
  output reg  rst_sync
);
  reg stage1;
  reg stage2;
  
  always @(posedge clk) begin
    if (!rst_n) begin
      stage1   <= 1'b0;
      stage2   <= 1'b0;
      rst_sync <= 1'b0;
    end else if (rst_n && en) begin
      stage1   <= 1'b1;
      stage2   <= stage1;
      rst_sync <= stage2;
    end else if (rst_n && !en) begin
      // en为0时，stage1保持不变
      stage1   <= stage1;
      stage2   <= stage1;
      rst_sync <= stage2;
    end
  end
endmodule