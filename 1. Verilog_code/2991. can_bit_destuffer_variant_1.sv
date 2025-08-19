//SystemVerilog
module can_bit_destuffer(
  input wire clk, rst_n,
  input wire data_in, data_valid,
  input wire destuffing_active,
  output reg data_out,
  output reg data_out_valid,
  output reg stuff_error
);
  reg [2:0] same_bit_count;
  reg last_bit;
  wire active_input;
  wire is_stuff_bit;
  wire is_error;
  
  // 定义活跃输入条件
  assign active_input = data_valid && destuffing_active;
  
  // 定义填充位检测条件
  assign is_stuff_bit = (same_bit_count == 4) && (data_in != last_bit);
  
  // 定义错误检测条件
  assign is_error = (same_bit_count == 4) && (data_in == last_bit);
  
  // Kogge-Stone加法器信号定义
  wire [2:0] a, b, sum;
  wire [2:0] p, g; // 生成和传播信号
  wire [2:0] p_stage1, g_stage1; // 第一级信号
  wire [2:0] p_stage2, g_stage2; // 第二级信号
  wire [2:0] carry; // 进位信号
  
  // 加法器输入
  assign a = same_bit_count;
  assign b = 3'b001;
  
  // Kogge-Stone加法器实现
  // 第0阶段：生成初始P和G信号
  assign p = a ^ b; // 传播信号
  assign g = a & b; // 生成信号
  
  // 第1阶段：计算跨1位的P和G信号
  assign p_stage1[0] = p[0];
  assign g_stage1[0] = g[0];
  assign p_stage1[1] = p[1] & p[0];
  assign g_stage1[1] = g[1] | (p[1] & g[0]);
  assign p_stage1[2] = p[2] & p[1];
  assign g_stage1[2] = g[2] | (p[2] & g[1]);
  
  // 第2阶段：计算跨2位的P和G信号
  assign p_stage2[0] = p_stage1[0];
  assign g_stage2[0] = g_stage1[0];
  assign p_stage2[1] = p_stage1[1];
  assign g_stage2[1] = g_stage1[1];
  assign p_stage2[2] = p_stage1[2] & p_stage1[0];
  assign g_stage2[2] = g_stage1[2] | (p_stage1[2] & g_stage1[0]);
  
  // 计算进位
  assign carry[0] = 1'b0; // 初始进位为0
  assign carry[1] = g_stage2[0];
  assign carry[2] = g_stage2[1];
  
  // 计算和
  assign sum = p ^ {carry[2:0]};
  
  // 比特计数器控制
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      same_bit_count <= 3'b000;
      last_bit <= 1'b0;
    end else if (active_input) begin
      if (is_stuff_bit) begin
        same_bit_count <= 3'b000;
      end else if (!is_error) begin
        same_bit_count <= (data_in == last_bit) ? sum : 3'b000;
      end
      
      last_bit <= data_in;
    end
  end
  
  // 数据输出控制
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data_out <= 1'b1;
      data_out_valid <= 1'b0;
    end else begin
      data_out_valid <= 1'b0;
      
      if (active_input && !is_stuff_bit && !is_error) begin
        data_out <= data_in;
        data_out_valid <= 1'b1;
      end
    end
  end
  
  // 错误检测控制
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      stuff_error <= 1'b0;
    end else if (active_input && is_error) begin
      stuff_error <= 1'b1;
    end
  end
  
endmodule