//SystemVerilog
module temperature_reset #(
  parameter HOT_THRESHOLD = 8'hC0
) (
  input wire clk,
  input wire [7:0] temperature,
  input wire rst_n,
  output reg temp_reset
);
  reg comparison_result;
  
  // 将比较逻辑提前到寄存器前
  always @(posedge clk or negedge rst_n)
    if (!rst_n)
      comparison_result <= 1'b0;
    else
      comparison_result <= (temperature > HOT_THRESHOLD);
  
  // 输出寄存器简化为直通比较结果
  always @(posedge clk or negedge rst_n)
    if (!rst_n)
      temp_reset <= 1'b0;
    else
      temp_reset <= comparison_result;
endmodule