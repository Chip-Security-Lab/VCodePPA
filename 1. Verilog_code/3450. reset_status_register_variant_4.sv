//SystemVerilog
module reset_status_register (
  input wire clk,
  input wire clear,
  input wire pwr_rst,
  input wire wdt_rst,
  input wire sw_rst,
  input wire ext_rst,
  output reg [7:0] rst_status
);
  
  // 创建组合逻辑用于重置状态计算
  reg [7:0] next_rst_status;
  
  // 为高扇出信号添加缓冲寄存器
  reg [7:0] next_rst_status_buf1;
  reg [7:0] next_rst_status_buf2;
  
  always @(*) begin
    // 保持当前状态作为默认值
    next_rst_status = rst_status;
    
    // 清除具有最低优先级
    if (clear)
      next_rst_status = 8'h00;
      
    // 并行处理各种重置源，避免串行if语句带来的延迟
    if (wdt_rst) next_rst_status[1] = 1'b1;
    if (sw_rst)  next_rst_status[2] = 1'b1;
    if (ext_rst) next_rst_status[3] = 1'b1;
  end
  
  // 缓冲寄存器，分散驱动负载，构建多级缓冲结构
  always @(posedge clk or posedge pwr_rst) begin
    if (pwr_rst) begin
      next_rst_status_buf1 <= 8'h01;
      next_rst_status_buf2 <= 8'h01;
    end else begin
      next_rst_status_buf1 <= next_rst_status;
      next_rst_status_buf2 <= next_rst_status;
    end
  end
  
  // 时序逻辑，统一时钟域处理，使用缓冲寄存器
  always @(posedge clk or posedge pwr_rst) begin
    if (pwr_rst)
      rst_status <= 8'h01;  // 电源重置具有最高优先级
    else
      rst_status <= (rst_status[7:4] == 4'b0) ? next_rst_status_buf1 : next_rst_status_buf2;
  end
  
endmodule