//SystemVerilog
module reset_propagation_monitor (
  input wire clk,
  input wire reset_src,
  input wire [3:0] reset_dst,
  output reg propagation_error
);
  reg reset_src_d;
  reg [7:0] timeout;
  reg checking;
  reg reset_src_sync;  // 新增的同步寄存器，用于前向重定时
  
  // 先行进位加法器信号定义
  wire [7:0] next_timeout;
  wire [7:0] g; // 生成信号
  wire [7:0] p; // 传播信号
  wire [8:0] c; // 进位信号，多一位
  
  // 生成和传播信号计算
  assign g[0] = 1'b0;  // 加1操作的生成信号
  assign p[0] = timeout[0];
  
  assign g[1] = timeout[1] & timeout[0];
  assign p[1] = timeout[1] | timeout[0];
  
  assign g[2] = timeout[2] & timeout[1];
  assign p[2] = timeout[2] | timeout[1];
  
  assign g[3] = timeout[3] & timeout[2];
  assign p[3] = timeout[3] | timeout[2];
  
  assign g[4] = timeout[4] & timeout[3];
  assign p[4] = timeout[4] | timeout[3];
  
  assign g[5] = timeout[5] & timeout[4];
  assign p[5] = timeout[5] | timeout[4];
  
  assign g[6] = timeout[6] & timeout[5];
  assign p[6] = timeout[6] | timeout[5];
  
  assign g[7] = timeout[7] & timeout[6];
  assign p[7] = timeout[7] | timeout[6];
  
  // 先行进位计算
  assign c[0] = 1'b1;  // 加1操作的初始进位
  assign c[1] = g[0] | (p[0] & c[0]);
  assign c[2] = g[1] | (p[1] & c[1]);
  assign c[3] = g[2] | (p[2] & c[2]);
  assign c[4] = g[3] | (p[3] & c[3]);
  assign c[5] = g[4] | (p[4] & c[4]);
  assign c[6] = g[5] | (p[5] & c[5]);
  assign c[7] = g[6] | (p[6] & c[6]);
  assign c[8] = g[7] | (p[7] & c[7]);
  
  // 计算下一个超时值
  assign next_timeout[0] = timeout[0] ^ c[0];
  assign next_timeout[1] = timeout[1] ^ c[1];
  assign next_timeout[2] = timeout[2] ^ c[2];
  assign next_timeout[3] = timeout[3] ^ c[3];
  assign next_timeout[4] = timeout[4] ^ c[4];
  assign next_timeout[5] = timeout[5] ^ c[5];
  assign next_timeout[6] = timeout[6] ^ c[6];
  assign next_timeout[7] = timeout[7] ^ c[7];
  
  // 前向重定时：先对reset_src进行寄存同步，减少输入到第一级寄存器的延迟
  always @(posedge clk) begin
    reset_src_sync <= reset_src;
  end
  
  // 进一步处理重定时信号
  always @(posedge clk) begin
    reset_src_d <= reset_src_sync;
    
    if (reset_src_sync && !reset_src_d) begin
      checking <= 1'b1;
      timeout <= 8'd0;
      propagation_error <= 1'b0;
    end else if (checking) begin
      timeout <= next_timeout;
      if (&reset_dst)
        checking <= 1'b0;
      else if (timeout == 8'hFF) begin
        propagation_error <= 1'b1;
        checking <= 1'b0;
      end
    end
  end
endmodule