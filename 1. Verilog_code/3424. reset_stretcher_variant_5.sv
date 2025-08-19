//SystemVerilog
module reset_stretcher #(
  parameter STRETCH_CYCLES = 16
) (
  input  wire clk,
  input  wire reset_in,
  output reg  reset_out
);
  
  localparam CNT_WIDTH = $clog2(STRETCH_CYCLES);
  reg [CNT_WIDTH:0] counter;
  
  // 合并计数器更新和输出控制逻辑到单个always块
  always @(posedge clk) begin
    if (reset_in) begin
      // 当外部复位有效时，立即输出复位并加载计数器
      counter <= STRETCH_CYCLES;
      reset_out <= 1'b1;
    end
    else if (|counter) begin  // 用按位或运算替代比较，更高效
      // 当计数器非零时，递减计数器并保持复位输出
      counter <= counter - 1'b1;
      reset_out <= 1'b1;
    end
    else begin
      // 计数完成，释放复位
      reset_out <= 1'b0;
    end
  end
  
endmodule