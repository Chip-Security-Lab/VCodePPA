//SystemVerilog
module reset_controller (
  input wire clk,                // 系统时钟
  input wire master_rst_n,       // 主复位信号，低电平有效
  input wire power_stable,       // 电源稳定指示
  output reg core_rst_n,         // 核心复位输出，低电平有效
  output reg periph_rst_n,       // 外设复位输出，低电平有效
  output reg io_rst_n            // IO复位输出，低电平有效
);
  
  // 使用One-Hot编码替代二进制计数器，减少解码逻辑
  localparam [3:0] RESET_ALL  = 4'b0001,
                   CORE_READY = 4'b0010,
                   PERIPH_READY = 4'b0100,
                   ALL_READY  = 4'b1000;
                   
  reg [3:0] rst_state, next_state;
  
  // 状态转换逻辑 - 分离组合逻辑和时序逻辑
  always @(*) begin
    // 默认保持当前状态和输出
    next_state = rst_state;
    
    if (power_stable) begin
      case (rst_state)
        RESET_ALL:   next_state = CORE_READY;
        CORE_READY:  next_state = PERIPH_READY;
        PERIPH_READY: next_state = ALL_READY;
        ALL_READY:   next_state = ALL_READY;  // 保持在最终状态
        default:     next_state = RESET_ALL;  // 安全默认值
      endcase
    end
  end
  
  // 状态寄存器更新
  always @(posedge clk or negedge master_rst_n) begin
    if (!master_rst_n) begin
      rst_state <= RESET_ALL;
    end else begin
      rst_state <= next_state;
    end
  end
  
  // 输出逻辑 - 为重置信号提供独立的控制
  always @(posedge clk or negedge master_rst_n) begin
    if (!master_rst_n) begin
      // 异步复位所有信号
      core_rst_n <= 1'b0;
      periph_rst_n <= 1'b0;
      io_rst_n <= 1'b0;
    end else begin
      // 根据状态选择性地释放复位信号
      core_rst_n <= (rst_state == RESET_ALL) ? 1'b0 : 1'b1;
      periph_rst_n <= (rst_state == RESET_ALL || rst_state == CORE_READY) ? 1'b0 : 1'b1;
      io_rst_n <= (rst_state != ALL_READY) ? 1'b0 : 1'b1;
    end
  end
  
endmodule