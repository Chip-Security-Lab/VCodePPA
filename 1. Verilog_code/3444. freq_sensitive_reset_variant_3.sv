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
  
  reg [3:0] main_counter_next;
  reg [3:0] ref_counter_next;
  
  // Brent-Kung加法器信号定义
  wire [3:0] p, g; // 传播和生成信号
  wire [1:0] p_level1, g_level1; // 第一级组合信号
  wire p_level2, g_level2; // 第二级组合信号
  wire [3:0] carry; // 进位信号
  wire ref_edge_detect;
  
  // 边沿检测信号
  assign ref_edge_detect = ref_clk && !ref_clk_sync;
  
  // 传播和生成信号计算
  assign p[0] = (main_counter[0] & (main_counter < 4'hF)) | (ref_counter[0] & ref_edge_detect);
  assign p[1] = (main_counter[1] & (main_counter < 4'hF)) | (ref_counter[1] & ref_edge_detect);
  assign p[2] = (main_counter[2] & (main_counter < 4'hF)) | (ref_counter[2] & ref_edge_detect);
  assign p[3] = (main_counter[3] & (main_counter < 4'hF)) | (ref_counter[3] & ref_edge_detect);
  
  assign g[0] = 1'b0; // 最低位没有前一个进位
  assign g[1] = main_counter[0] & (main_counter < 4'hF) | (ref_counter[0] & ref_edge_detect);
  assign g[2] = main_counter[1] & main_counter[0] & (main_counter < 4'hF) | (ref_counter[1] & ref_counter[0] & ref_edge_detect);
  assign g[3] = main_counter[2] & main_counter[1] & main_counter[0] & (main_counter < 4'hF) | 
                (ref_counter[2] & ref_counter[1] & ref_counter[0] & ref_edge_detect);
  
  // Brent-Kung树 - 第一级
  assign p_level1[0] = p[1] & p[0];
  assign g_level1[0] = g[1] | (p[1] & g[0]);
  
  assign p_level1[1] = p[3] & p[2];
  assign g_level1[1] = g[3] | (p[3] & g[2]);
  
  // Brent-Kung树 - 第二级
  assign p_level2 = p_level1[1] & p_level1[0];
  assign g_level2 = g_level1[1] | (p_level1[1] & g_level1[0]);
  
  // 计算进位
  assign carry[0] = 1'b0; // 最低位进位为0
  assign carry[1] = g[0];
  assign carry[2] = g_level1[0];
  assign carry[3] = g_level2;
  
  // 使用if-else结构代替条件运算符计算下一个计数值
  always @(*) begin
    if (ref_edge_detect) begin
      main_counter_next = 4'd0;
    end else begin
      if (main_counter < 4'hF) begin
        main_counter_next = (main_counter ^ p) ^ {carry[3:1], 1'b0};
      end else begin
        main_counter_next = main_counter;
      end
    end
  end
  
  always @(*) begin
    if (ref_edge_detect) begin
      ref_counter_next = (ref_counter ^ p) ^ {carry[3:1], 1'b0};
    end else begin
      ref_counter_next = ref_counter;
    end
  end
  
  always @(posedge main_clk) begin
    ref_clk_sync <= ref_clk;
    main_counter <= main_counter_next;
    ref_counter <= ref_counter_next;
    
    if (main_counter > CLOCK_COUNT) begin
      reset_out <= 1'b1;
    end else begin
      reset_out <= 1'b0;
    end
  end
endmodule