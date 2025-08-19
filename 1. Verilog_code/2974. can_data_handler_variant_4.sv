//SystemVerilog
module can_data_handler #(
  parameter DATA_WIDTH = 8,
  parameter BUFFER_DEPTH = 4
)(
  input wire clk,
  input wire rst_n,
  input wire [DATA_WIDTH-1:0] tx_data,
  input wire tx_valid,
  output wire tx_ready,
  input wire [10:0] msg_id,
  output wire [DATA_WIDTH-1:0] rx_data,
  output wire rx_valid,
  input wire rx_ready
);

  // 参数缓冲寄存器
  localparam DATA_WIDTH_BUFFERED = DATA_WIDTH;
  localparam BUFFER_DEPTH_BUFFERED = BUFFER_DEPTH;
  
  // 时钟与复位缓冲
  wire clk_buf1, clk_buf2;
  wire rst_n_buf1, rst_n_buf2;
  
  // 时钟树缓冲
  assign clk_buf1 = clk;
  assign clk_buf2 = clk;
  
  // 复位树缓冲
  assign rst_n_buf1 = rst_n;
  assign rst_n_buf2 = rst_n;
  
  // 数据缓冲寄存器
  reg [DATA_WIDTH-1:0] tx_data_buf1, tx_data_buf2;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_data_buf1 <= {DATA_WIDTH{1'b0}};
      tx_data_buf2 <= {DATA_WIDTH{1'b0}};
    end else begin
      tx_data_buf1 <= tx_data;
      tx_data_buf2 <= tx_data;
    end
  end

  // 内部连线
  wire [DATA_WIDTH-1:0] tx_buffer_data;
  wire tx_buffer_full;
  wire tx_buffer_empty;
  wire tx_buffer_rd_en;
  
  // TX缓冲区管理子模块
  tx_buffer_controller #(
    .DATA_WIDTH(DATA_WIDTH_BUFFERED),
    .BUFFER_DEPTH(BUFFER_DEPTH_BUFFERED)
  ) tx_buffer_inst (
    .clk(clk_buf1),
    .rst_n(rst_n_buf1),
    .tx_data(tx_data_buf1),
    .tx_valid(tx_valid),
    .tx_ready(tx_ready),
    .tx_buffer_data(tx_buffer_data),
    .tx_buffer_empty(tx_buffer_empty),
    .tx_buffer_rd_en(tx_buffer_rd_en)
  );
  
  // RX数据处理子模块
  rx_data_processor #(
    .DATA_WIDTH(DATA_WIDTH_BUFFERED)
  ) rx_processor_inst (
    .clk(clk_buf2),
    .rst_n(rst_n_buf2),
    .msg_id(msg_id),
    .tx_buffer_data(tx_buffer_data),
    .tx_buffer_empty(tx_buffer_empty),
    .tx_buffer_rd_en(tx_buffer_rd_en),
    .rx_data(rx_data),
    .rx_valid(rx_valid),
    .rx_ready(rx_ready)
  );

endmodule

// TX缓冲区控制模块
module tx_buffer_controller #(
  parameter DATA_WIDTH = 8,
  parameter BUFFER_DEPTH = 4
)(
  input wire clk,
  input wire rst_n,
  input wire [DATA_WIDTH-1:0] tx_data,
  input wire tx_valid,
  output wire tx_ready,
  output reg [DATA_WIDTH-1:0] tx_buffer_data,
  output wire tx_buffer_empty,
  input wire tx_buffer_rd_en
);
  
  // 内部参数缓冲，减少参数扇出
  localparam DEPTH = BUFFER_DEPTH;
  localparam WIDTH = DATA_WIDTH;
  localparam PTR_WIDTH = $clog2(DEPTH);
  
  // 缓冲区存储
  reg [WIDTH-1:0] tx_buffer [0:DEPTH-1];
  reg [$clog2(DEPTH):0] tx_count;
  reg [PTR_WIDTH-1:0] tx_rd_ptr, tx_wr_ptr;
  
  // 状态信号缓冲
  reg tx_buffer_empty_reg;
  reg tx_ready_reg;
  
  // 状态信号缓冲寄存器
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_buffer_empty_reg <= 1'b1;
      tx_ready_reg <= 1'b1;
    end else begin
      tx_buffer_empty_reg <= (tx_count == 0);
      tx_ready_reg <= (tx_count < DEPTH);
    end
  end
  
  // 状态信号输出
  assign tx_ready = tx_ready_reg;
  assign tx_buffer_empty = tx_buffer_empty_reg;
  
  // 缓冲区写入逻辑
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_count <= 0;
      tx_rd_ptr <= 0;
      tx_wr_ptr <= 0;
    end else begin
      // 写入操作
      if (tx_valid && tx_ready_reg) begin
        tx_buffer[tx_wr_ptr] <= tx_data;
        tx_wr_ptr <= (tx_wr_ptr + 1) % DEPTH;
        
        // 只读或只写时的计数器更新
        if (!(tx_buffer_rd_en && !tx_buffer_empty_reg)) begin
          tx_count <= tx_count + 1;
        end
      end
      
      // 读取操作
      if (tx_buffer_rd_en && !tx_buffer_empty_reg) begin
        tx_rd_ptr <= (tx_rd_ptr + 1) % DEPTH;
        
        // 只读或只写时的计数器更新
        if (!(tx_valid && tx_ready_reg)) begin
          tx_count <= tx_count - 1;
        end
      end
      
      // 同时读写时的计数器处理
      if ((tx_valid && tx_ready_reg) && (tx_buffer_rd_en && !tx_buffer_empty_reg)) begin
        tx_count <= tx_count; // 保持不变
      end
    end
  end
  
  // 读取数据输出
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_buffer_data <= {WIDTH{1'b0}};
    end else if (!tx_buffer_empty_reg) begin
      tx_buffer_data <= tx_buffer[tx_rd_ptr];
    end
  end
  
endmodule

// RX数据处理模块
module rx_data_processor #(
  parameter DATA_WIDTH = 8
)(
  input wire clk,
  input wire rst_n,
  input wire [10:0] msg_id,
  input wire [DATA_WIDTH-1:0] tx_buffer_data,
  input wire tx_buffer_empty,
  output reg tx_buffer_rd_en,
  output reg [DATA_WIDTH-1:0] rx_data,
  output reg rx_valid,
  input wire rx_ready
);

  // 内部参数缓冲，减少参数扇出
  localparam WIDTH = DATA_WIDTH;

  // 状态机编码
  localparam IDLE = 2'b00;
  localparam PROCESS = 2'b01;
  localparam WAIT_ACK = 2'b10;
  
  reg [1:0] state, next_state;
  
  // 缓冲寄存器
  reg tx_buffer_empty_buf;
  reg [10:0] msg_id_buf;
  reg [DATA_WIDTH-1:0] tx_buffer_data_buf;
  
  // 输入缓冲，减少扇出负载
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_buffer_empty_buf <= 1'b1;
      msg_id_buf <= 11'b0;
      tx_buffer_data_buf <= {WIDTH{1'b0}};
    end else begin
      tx_buffer_empty_buf <= tx_buffer_empty;
      msg_id_buf <= msg_id;
      tx_buffer_data_buf <= tx_buffer_data;
    end
  end
  
  // 状态转换逻辑
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
    end else begin
      state <= next_state;
    end
  end
  
  // 下一状态逻辑和输出逻辑
  always @(*) begin
    // 默认值
    next_state = state;
    tx_buffer_rd_en = 1'b0;
    rx_valid = 1'b0;
    
    case (state)
      IDLE: begin
        if (!tx_buffer_empty_buf) begin
          next_state = PROCESS;
          tx_buffer_rd_en = 1'b1;
        end
      end
      
      PROCESS: begin
        next_state = WAIT_ACK;
        rx_valid = 1'b1;
      end
      
      WAIT_ACK: begin
        rx_valid = 1'b1;
        if (rx_ready) begin
          next_state = IDLE;
        end
      end
      
      default: next_state = IDLE;
    endcase
  end
  
  // 数据处理逻辑
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_data <= {WIDTH{1'b0}};
    end else if (state == PROCESS) begin
      // 根据msg_id进行数据处理
      if (msg_id_buf[10]) begin
        // 高优先级消息处理
        rx_data <= tx_buffer_data_buf;
      end else begin
        // 普通消息处理
        rx_data <= tx_buffer_data_buf;
      end
    end
  end
  
endmodule