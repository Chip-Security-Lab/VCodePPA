//SystemVerilog
module timeout_counter #(parameter TIMEOUT = 100)(
  input wire clk, manual_rst, enable,
  output reg timeout_flag
);
  localparam CNT_WIDTH = $clog2(TIMEOUT);
  reg [CNT_WIDTH-1:0] counter; // 优化位宽，精确匹配所需位数
  
  // 使用范围检查替代精确比较，可能更适合某些FPGA架构
  wire timeout_reached = (counter >= TIMEOUT - 1);
  
  always @(posedge clk) begin
    if (manual_rst) begin
      counter <= 'b0; // 使用简化的复位值表示
      timeout_flag <= 1'b0;
    end else if (enable) begin
      if (timeout_reached) begin
        counter <= 'b0;
        timeout_flag <= 1'b1;
      end else begin
        counter <= counter + 1'b1;
        timeout_flag <= 1'b0;
      end
    end
  end
endmodule