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
  // Register map
  localparam REG_TX_DATA = 4'h0;    // Write: TX data
  localparam REG_RX_DATA = 4'h1;    // Read: RX data
  localparam REG_STATUS = 4'h2;     // Read: Status register
  localparam REG_CONTROL = 4'h3;    // R/W: Control register
  localparam REG_BAUD_DIV = 4'h4;   // R/W: Baud rate divider
  
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
      tx_data_reg <= 0;
      control_reg <= 8'h30; // Enable TX and RX by default
      baud_div_reg <= 8'd16; // Default baud divider
      tx_start <= 0;
      status_reg <= 0; // 添加初始化
      rx_data_reg <= 0; // 添加初始化
    end else begin
      tx_start <= 0; // Auto-clear tx_start
      
      // Write operations
      if (write_en) begin
        case (addr)
          REG_TX_DATA: begin
            tx_data_reg <= wdata;
            if (control_reg[4]) tx_start <= 1; // Auto-start TX if enabled
          end
          REG_CONTROL: control_reg <= wdata;
          REG_BAUD_DIV: baud_div_reg <= wdata;
          default: ; // No operation for other addresses
        endcase
      end
      
      // Clear status bits when read
      if (read_en && addr == REG_STATUS) begin
        status_reg[5] <= 0; // Clear overrun flag on read
      end
      
      // Update status register
      status_reg[7] <= rx_ready;
      status_reg[6] <= tx_busy;
      status_reg[4] <= frame_error;
      
      // Handle RX data and overrun detection
      if (rx_ready) begin
        if (status_reg[7]) status_reg[5] <= 1; // Set overrun flag
        rx_data_reg <= rx_data;
      end
    end
  end
  
  // Read operations
  always @(*) begin
    case (addr)
      REG_RX_DATA: rdata = rx_data_reg;
      REG_STATUS:  rdata = status_reg;
      REG_CONTROL: rdata = control_reg;
      REG_BAUD_DIV: rdata = baud_div_reg;
      default:     rdata = 8'h00;
    endcase
  end
  
  // 为引用的模块创建简单的桩实现
  
  // 简单的TX桩
  assign tx_out = 1'b1; // 空闲状态为高电平
  assign tx_busy = tx_start; // 启动时忙
  assign tx_done = !tx_busy && tx_start;
  
  // 简单的RX桩
  assign rx_ready = rx_in; // 输入高电平时就绪
  assign rx_data = 8'hAA; // 测试数据
  assign frame_error = 1'b0; // 无错误
  
endmodule