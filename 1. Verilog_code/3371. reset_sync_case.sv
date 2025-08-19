module reset_sync_case(
  input  wire clk,
  input  wire rst_n,
  output reg  rst_out
);
  reg stage1;
  
  // 用if-else替代可能导致问题的case语句
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      stage1 <= 1'b0;
      rst_out <= 1'b0;
    end else begin
      stage1 <= 1'b1;
      rst_out <= stage1;
    end
  end
endmodule