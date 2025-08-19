//SystemVerilog
module uart_multi_channel #(parameter CHANNELS = 4) (
  input  wire clk, rst_n,
  input  wire [CHANNELS-1:0] rx_in,
  output wire [CHANNELS-1:0] tx_out,
  input  wire [7:0] tx_data [0:CHANNELS-1],
  input  wire [CHANNELS-1:0] tx_valid,
  output wire [CHANNELS-1:0] tx_ready,
  output wire [7:0] rx_data [0:CHANNELS-1],
  output wire [CHANNELS-1:0] rx_valid,
  input  wire [CHANNELS-1:0] rx_ready
);
  
  // 实例化UART通道阵列
  genvar i;
  generate
    for (i = 0; i < CHANNELS; i = i + 1) begin : channel_array
      uart_channel uart_ch_inst (
        .clk        (clk),
        .rst_n      (rst_n),
        .rx_in      (rx_in[i]),
        .tx_out     (tx_out[i]),
        .tx_data    (tx_data[i]),
        .tx_valid   (tx_valid[i]),
        .tx_ready   (tx_ready[i]),
        .rx_data    (rx_data[i]),
        .rx_valid   (rx_valid[i]),
        .rx_ready   (rx_ready[i])
      );
    end
  endgenerate
  
endmodule

// 单个UART通道模块，包含发送和接收功能
module uart_channel (
  input  wire clk, rst_n,
  input  wire rx_in,
  output wire tx_out,
  input  wire [7:0] tx_data,
  input  wire tx_valid,
  output wire tx_ready,
  output wire [7:0] rx_data,
  output wire rx_valid,
  input  wire rx_ready
);

  // 实例化发送和接收子模块
  uart_transmitter tx_unit (
    .clk       (clk),
    .rst_n     (rst_n),
    .tx_data   (tx_data),
    .tx_valid  (tx_valid),
    .tx_ready  (tx_ready),
    .tx_out    (tx_out)
  );
  
  uart_receiver rx_unit (
    .clk       (clk),
    .rst_n     (rst_n),
    .rx_in     (rx_in),
    .rx_data   (rx_data),
    .rx_valid  (rx_valid),
    .rx_ready  (rx_ready)
  );

endmodule

// UART发送器模块
module uart_transmitter (
  input  wire clk, rst_n,
  input  wire [7:0] tx_data,
  input  wire tx_valid,
  output reg  tx_ready,
  output reg  tx_out
);
  // 状态编码
  localparam [1:0] IDLE  = 2'b00,
                   START = 2'b01,
                   DATA  = 2'b10,
                   STOP  = 2'b11;
  
  // 内部寄存器
  reg [1:0] tx_state;
  reg [2:0] tx_bit_count;
  reg [7:0] tx_shift;
  
  // 内部信号
  wire tx_data_ready;
  wire tx_bit_last;
  
  // 优化的控制逻辑
  assign tx_data_ready = tx_valid & tx_ready;
  assign tx_bit_last = (tx_bit_count == 3'b111);
  
  // TX 状态机
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_state <= IDLE;
      tx_bit_count <= 3'b000;
      tx_shift <= 8'h00;
      tx_out <= 1'b1;
      tx_ready <= 1'b1;
    end else begin
      case (tx_state)
        IDLE: begin
          tx_out <= 1'b1;
          if (tx_data_ready) begin
            tx_state <= START;
            tx_shift <= tx_data;
            tx_ready <= 1'b0;
          end
        end
        START: begin
          tx_out <= 1'b0;
          tx_state <= DATA;
          tx_bit_count <= 3'b000;
        end
        DATA: begin
          tx_out <= tx_shift[0];
          // 优化的移位操作
          tx_shift <= {1'b0, tx_shift[7:1]};
          if (tx_bit_last) 
            tx_state <= STOP;
          else 
            tx_bit_count <= tx_bit_count + 3'b001;
        end
        STOP: begin
          tx_out <= 1'b1;
          tx_state <= IDLE;
          tx_ready <= 1'b1;
        end
      endcase
    end
  end
endmodule

// UART接收器模块
module uart_receiver (
  input  wire clk, rst_n,
  input  wire rx_in,
  output reg [7:0] rx_data,
  output reg rx_valid,
  input  wire rx_ready
);
  // 状态编码
  localparam [1:0] IDLE  = 2'b00,
                   START = 2'b01,
                   DATA  = 2'b10,
                   STOP  = 2'b11;
  
  // 内部寄存器
  reg [1:0] rx_state;
  reg [2:0] rx_bit_count;
  reg [7:0] rx_shift;
  
  // 内部信号
  wire rx_bit_last;
  wire rx_data_complete;
  
  // 优化的控制逻辑
  assign rx_bit_last = (rx_bit_count == 3'b111);
  assign rx_data_complete = (rx_in == 1'b1) & ~rx_valid;
  
  // RX 状态机
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_state <= IDLE;
      rx_bit_count <= 3'b000;
      rx_shift <= 8'h00;
      rx_data <= 8'h00;
      rx_valid <= 1'b0;
    end else begin
      // 优化的清除有效标志逻辑
      if (rx_valid & rx_ready)
        rx_valid <= 1'b0;
      
      case (rx_state)
        IDLE: begin
          if (rx_in == 1'b0) 
            rx_state <= START;
        end
        START: begin 
          rx_state <= DATA; 
          rx_bit_count <= 3'b000; 
        end
        DATA: begin
          // 优化过的数据捕获逻辑
          rx_shift <= {rx_in, rx_shift[7:1]};
          if (rx_bit_last)
            rx_state <= STOP;
          else
            rx_bit_count <= rx_bit_count + 3'b001;
        end
        STOP: begin
          rx_state <= IDLE;
          if (rx_data_complete) begin
            rx_data <= rx_shift;
            rx_valid <= 1'b1;
          end
        end
      endcase
    end
  end
endmodule