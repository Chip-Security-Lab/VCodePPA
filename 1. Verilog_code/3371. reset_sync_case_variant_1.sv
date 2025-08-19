//SystemVerilog
module reset_sync_case(
  input  wire clk,
  input  wire rst_n,
  output reg  rst_out
);
  // 使用两级触发器实现可靠的复位同步
  (* dont_touch = "true" *) reg rst_n_meta;
  (* dont_touch = "true" *) reg rst_n_sync;
  
  // 复位同步器实现
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // 异步复位时立即清零各级触发器
      rst_n_meta <= 1'b0;
      rst_n_sync <= 1'b0;
    end else begin
      // 正常操作时双级移位传递复位信号
      rst_n_meta <= 1'b1;
      rst_n_sync <= rst_n_meta;
    end
  end
  
  // 输出复位信号生成
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // 异步复位直接清零输出，加速复位响应
      rst_out <= 1'b0;
    end else begin
      // 正常操作时使用同步过的复位信号
      rst_out <= rst_n_sync;
    end
  end
endmodule