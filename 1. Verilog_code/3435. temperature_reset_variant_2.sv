//SystemVerilog
module temperature_reset #(
  parameter HOT_THRESHOLD = 8'hC0
) (
  input wire clk,
  input wire [7:0] temperature,
  input wire rst_n,
  output reg temp_reset
);

  // 流水线寄存器和信号
  reg [7:0] temperature_stage1;
  reg valid_stage1;
  reg compare_result_stage2;
  reg valid_stage2;
  
  // 第一级流水线 - 捕获输入
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      temperature_stage1 <= 8'h00;
      valid_stage1 <= 1'b0;
    end else begin
      temperature_stage1 <= temperature;
      valid_stage1 <= 1'b1;
    end
  end
  
  // 第二级流水线 - 执行比较
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      compare_result_stage2 <= 1'b0;
      valid_stage2 <= 1'b0;
    end else begin
      compare_result_stage2 <= (temperature_stage1 >= (HOT_THRESHOLD + 1'b1));
      valid_stage2 <= valid_stage1;
    end
  end
  
  // 第三级流水线 - 输出结果
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      temp_reset <= 1'b0;
    end else if (valid_stage2) begin
      temp_reset <= compare_result_stage2;
    end
  end
  
endmodule