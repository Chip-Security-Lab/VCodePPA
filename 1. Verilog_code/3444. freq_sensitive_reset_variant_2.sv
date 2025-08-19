//SystemVerilog
module freq_sensitive_reset #(
  parameter CLOCK_COUNT = 8
) (
  input wire main_clk,
  input wire ref_clk,
  output reg reset_out
);
  reg [3:0] main_counter;
  reg [3:0] ref_counter;
  reg ref_clk_sync;
  
  // 主计数器的增量计算 - 优化布尔表达式
  wire [3:0] sum_main;
  assign sum_main[0] = ~main_counter[0]; // 异或1等于取反
  assign sum_main[1] = main_counter[1] ^ main_counter[0]; // 进位传播
  assign sum_main[2] = main_counter[2] ^ (main_counter[1] & main_counter[0]);
  assign sum_main[3] = main_counter[3] ^ (main_counter[2] & main_counter[1] & main_counter[0]);
  
  // 参考计数器的增量计算 - 优化布尔表达式
  wire [3:0] sum_ref;
  assign sum_ref[0] = ~ref_counter[0]; // 异或1等于取反
  assign sum_ref[1] = ref_counter[1] ^ ref_counter[0]; // 进位传播
  assign sum_ref[2] = ref_counter[2] ^ (ref_counter[1] & ref_counter[0]);
  assign sum_ref[3] = ref_counter[3] ^ (ref_counter[2] & ref_counter[1] & ref_counter[0]);
  
  always @(posedge main_clk) begin
    ref_clk_sync <= ref_clk;
    
    if (ref_clk && !ref_clk_sync) begin
      // 参考时钟上升沿检测
      main_counter <= 4'd0;
      ref_counter <= sum_ref;
    end else if (main_counter < 4'hF) begin
      // 主计数器递增
      main_counter <= sum_main;
    end
    
    // 重置信号生成
    reset_out <= (main_counter > CLOCK_COUNT);
  end
endmodule