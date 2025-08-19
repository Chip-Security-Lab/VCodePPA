//SystemVerilog
module uart_memory_mapped #(parameter ADDR_WIDTH = 4) (
  input wire clk, reset_n,
  // Bus interface
  input wire [ADDR_WIDTH-1:0] addr,
  input wire [7:0] wdata,
  input wire write_en, read_en,
  output reg [7:0] rdata,
  // UART signals
  input wire rx_in,
  output wire tx_out
);
  // Register map - 使用独热编码以优化地址解码
  localparam REG_TX_DATA  = 4'h0;    // Write: TX data
  localparam REG_RX_DATA  = 4'h1;    // Read: RX data
  localparam REG_STATUS   = 4'h2;    // Read: Status register
  localparam REG_CONTROL  = 4'h3;    // R/W: Control register
  localparam REG_BAUD_DIV = 4'h4;    // R/W: Baud rate divider
  
  // 地址解码信号
  wire addr_is_tx_data  = (addr == REG_TX_DATA);
  wire addr_is_rx_data  = (addr == REG_RX_DATA);
  wire addr_is_status   = (addr == REG_STATUS);
  wire addr_is_control  = (addr == REG_CONTROL);
  wire addr_is_baud_div = (addr == REG_BAUD_DIV);
  
  // Internal registers
  reg [7:0] tx_data_reg;
  reg [7:0] rx_data_reg;
  reg [7:0] status_reg;  // [7:rx_ready, 6:tx_busy, 5:rx_overrun, 4:frame_err, 3-0:reserved]
  reg [7:0] control_reg; // [7:rx_int_en, 6:tx_int_en, 5:rx_en, 4:tx_en, 3-0:reserved]
  reg [7:0] baud_div_reg;
  
  // UART control signals
  reg tx_start;
  wire tx_busy, rx_ready;
  wire [7:0] rx_data;
  wire frame_error;
  wire tx_done;
  
  // Bus interface logic
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      tx_data_reg <= 8'h0;
      control_reg <= 8'h30; // Enable TX and RX by default
      baud_div_reg <= 8'd16; // Default baud divider
      tx_start <= 1'b0;
      status_reg <= 8'h0;
      rx_data_reg <= 8'h0;
    end else begin
      // 默认信号状态
      tx_start <= 1'b0; // Auto-clear tx_start
      
      // 写操作 - 使用预解码地址信号提高效率
      if (write_en) begin
        // 使用并行编码提高效率，降低比较链延迟
        case (1'b1) // 优先级编码
          addr_is_tx_data: begin
            tx_data_reg <= wdata;
            if (control_reg[4]) tx_start <= 1'b1; // Auto-start TX if enabled
          end
          
          addr_is_control:
            control_reg <= wdata;
          
          addr_is_baud_div:
            baud_div_reg <= wdata;
            
          default: ; // 无操作
        endcase
      end
      
      // 读状态寄存器时清除标志位
      if (read_en && addr_is_status) begin
        status_reg[5] <= 1'b0; // Clear overrun flag on read
      end
      
      // 更新状态寄存器 - 使用并行赋值提高效率
      status_reg[7:6] <= {rx_ready, tx_busy};
      status_reg[4] <= frame_error;
      
      // 处理RX数据和溢出检测
      if (rx_ready) begin
        rx_data_reg <= rx_data;
        // 仅在当前已有数据未读取的情况下设置溢出标志
        if (status_reg[7]) status_reg[5] <= 1'b1;
      end
    end
  end
  
  // 读操作 - 优化比较逻辑，使用case提高效率
  always @(*) begin
    // 使用case替代多个if语句，降低比较链路径
    case (addr)
      REG_RX_DATA:  rdata = rx_data_reg;
      REG_STATUS:   rdata = status_reg;
      REG_CONTROL:  rdata = control_reg;
      REG_BAUD_DIV: rdata = baud_div_reg;
      default:      rdata = 8'h00;
    endcase
  end
  
  // 桩实现
  
  // TX桩
  assign tx_out = 1'b1; // 空闲状态为高电平
  assign tx_busy = tx_start; // 启动时忙
  assign tx_done = !tx_busy && tx_start;
  
  // RX桩
  assign rx_ready = rx_in; // 输入高电平时就绪
  assign rx_data = 8'hAA; // 测试数据
  assign frame_error = 1'b0; // 无错误
  
endmodule