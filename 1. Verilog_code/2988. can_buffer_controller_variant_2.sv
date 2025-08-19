//SystemVerilog
// 顶层模块 - 流水线化CAN缓冲区控制器
module can_buffer_controller #(
  parameter BUFFER_DEPTH = 8
)(
  input wire clk, rst_n,
  input wire rx_done,
  input wire [10:0] rx_id,
  input wire [7:0] rx_data [0:7],
  input wire [3:0] rx_dlc,
  input wire tx_request, tx_done,
  output wire [10:0] tx_id,
  output wire [7:0] tx_data [0:7],
  output wire [3:0] tx_dlc,
  output wire buffer_full, buffer_empty,
  output wire [3:0] buffer_level
);
  // 内部连线
  wire [$clog2(BUFFER_DEPTH):0] rd_ptr, wr_ptr;
  wire write_en, read_en;
  
  // 流水线阶段valid信号
  wire status_valid_stage1, status_valid_stage2;
  wire data_valid_stage1, data_valid_stage2;
  
  // 流水线状态控制模块
  buffer_status_controller_pipelined #(
    .BUFFER_DEPTH(BUFFER_DEPTH)
  ) status_ctrl (
    .clk(clk),
    .rst_n(rst_n),
    .rx_done(rx_done),
    .tx_request(tx_request),
    .tx_done(tx_done),
    .buffer_full(buffer_full),
    .buffer_empty(buffer_empty),
    .buffer_level(buffer_level),
    .rd_ptr(rd_ptr),
    .wr_ptr(wr_ptr),
    .write_en(write_en),
    .read_en(read_en),
    .valid_stage1(status_valid_stage1),
    .valid_stage2(status_valid_stage2)
  );
  
  // 流水线数据存储与访问模块
  buffer_data_manager_pipelined #(
    .BUFFER_DEPTH(BUFFER_DEPTH)
  ) data_mgr (
    .clk(clk),
    .rst_n(rst_n),
    .rx_id(rx_id),
    .rx_data(rx_data),
    .rx_dlc(rx_dlc),
    .write_en(write_en),
    .read_en(read_en),
    .rd_ptr(rd_ptr),
    .wr_ptr(wr_ptr),
    .tx_id(tx_id),
    .tx_data(tx_data),
    .tx_dlc(tx_dlc),
    .valid_stage1(data_valid_stage1),
    .valid_stage2(data_valid_stage2)
  );
  
endmodule

// 流水线化缓冲区状态控制模块
module buffer_status_controller_pipelined #(
  parameter BUFFER_DEPTH = 8
)(
  input wire clk, rst_n,
  input wire rx_done, tx_request, tx_done,
  output reg buffer_full, buffer_empty,
  output reg [3:0] buffer_level,
  output reg [$clog2(BUFFER_DEPTH):0] rd_ptr, wr_ptr,
  output reg write_en, read_en,
  output reg valid_stage1, valid_stage2
);
  // 流水线寄存器 - 第一级
  reg rx_done_stage1, tx_request_stage1, tx_done_stage1;
  reg buffer_full_stage1, buffer_empty_stage1;
  reg [3:0] buffer_level_stage1;
  reg [$clog2(BUFFER_DEPTH):0] rd_ptr_stage1, wr_ptr_stage1;
  
  // 流水线寄存器 - 第二级
  reg rx_done_stage2, tx_request_stage2, tx_done_stage2;
  reg write_en_internal, read_en_internal;
  reg [$clog2(BUFFER_DEPTH):0] rd_ptr_next, wr_ptr_next;
  reg buffer_full_next, buffer_empty_next;
  reg [3:0] buffer_level_next;
  
  // 第一级流水线 - 输入捕获和初步计算
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_done_stage1 <= 0;
      tx_request_stage1 <= 0;
      tx_done_stage1 <= 0;
      buffer_full_stage1 <= 0;
      buffer_empty_stage1 <= 1;
      buffer_level_stage1 <= 0;
      rd_ptr_stage1 <= 0;
      wr_ptr_stage1 <= 0;
      valid_stage1 <= 0;
    end else begin
      // 捕获输入到第一级流水线
      rx_done_stage1 <= rx_done;
      tx_request_stage1 <= tx_request;
      tx_done_stage1 <= tx_done;
      buffer_full_stage1 <= buffer_full;
      buffer_empty_stage1 <= buffer_empty;
      buffer_level_stage1 <= buffer_level;
      rd_ptr_stage1 <= rd_ptr;
      wr_ptr_stage1 <= wr_ptr;
      valid_stage1 <= 1;
    end
  end
  
  // 第二级流水线 - 处理和决策
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_done_stage2 <= 0;
      tx_request_stage2 <= 0;
      tx_done_stage2 <= 0;
      write_en_internal <= 0;
      read_en_internal <= 0;
      rd_ptr_next <= 0;
      wr_ptr_next <= 0;
      buffer_full_next <= 0;
      buffer_empty_next <= 1;
      buffer_level_next <= 0;
      valid_stage2 <= 0;
    end else begin
      // 默认状态
      write_en_internal <= 0;
      read_en_internal <= 0;
      
      // 传递寄存器值
      rx_done_stage2 <= rx_done_stage1;
      tx_request_stage2 <= tx_request_stage1;
      tx_done_stage2 <= tx_done_stage1;
      
      // 计算新状态
      rd_ptr_next <= rd_ptr_stage1;
      wr_ptr_next <= wr_ptr_stage1;
      buffer_full_next <= buffer_full_stage1;
      buffer_empty_next <= buffer_empty_stage1;
      buffer_level_next <= buffer_level_stage1;
      
      // 处理写入请求
      if (rx_done_stage1 && !buffer_full_stage1) begin
        write_en_internal <= 1;
        wr_ptr_next <= (wr_ptr_stage1 == BUFFER_DEPTH-1) ? 0 : wr_ptr_stage1 + 1;
        buffer_level_next <= buffer_level_stage1 + 1;
        buffer_empty_next <= 0;
        buffer_full_next <= (buffer_level_stage1 == BUFFER_DEPTH-1) || 
                          ((wr_ptr_stage1 + 1) % BUFFER_DEPTH == rd_ptr_stage1);
      end
      
      // 处理读取请求
      if (tx_request_stage1 && !buffer_empty_stage1 && tx_done_stage1) begin
        read_en_internal <= 1;
        rd_ptr_next <= (rd_ptr_stage1 == BUFFER_DEPTH-1) ? 0 : rd_ptr_stage1 + 1;
        buffer_level_next <= buffer_level_stage1 - 1;
        buffer_full_next <= 0;
        buffer_empty_next <= (buffer_level_stage1 == 1) || 
                           ((rd_ptr_stage1 + 1) % BUFFER_DEPTH == wr_ptr_stage1);
      end
      
      valid_stage2 <= valid_stage1;
    end
  end
  
  // 第三级 - 更新输出寄存器
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rd_ptr <= 0;
      wr_ptr <= 0;
      buffer_full <= 0;
      buffer_empty <= 1;
      buffer_level <= 0;
      write_en <= 0;
      read_en <= 0;
    end else begin
      if (valid_stage2) begin
        rd_ptr <= rd_ptr_next;
        wr_ptr <= wr_ptr_next;
        buffer_full <= buffer_full_next;
        buffer_empty <= buffer_empty_next;
        buffer_level <= buffer_level_next;
        write_en <= write_en_internal;
        read_en <= read_en_internal;
      end
    end
  end
endmodule

// 流水线化缓冲区数据管理模块
module buffer_data_manager_pipelined #(
  parameter BUFFER_DEPTH = 8
)(
  input wire clk, rst_n,
  input wire [10:0] rx_id,
  input wire [7:0] rx_data [0:7],
  input wire [3:0] rx_dlc,
  input wire write_en, read_en,
  input wire [$clog2(BUFFER_DEPTH):0] rd_ptr, wr_ptr,
  output reg [10:0] tx_id,
  output reg [7:0] tx_data [0:7],
  output reg [3:0] tx_dlc,
  output reg valid_stage1, valid_stage2
);
  // 存储缓冲区声明
  reg [10:0] id_buffer [0:BUFFER_DEPTH-1];
  reg [7:0] data_buffer [0:BUFFER_DEPTH-1][0:7];
  reg [3:0] dlc_buffer [0:BUFFER_DEPTH-1];
  
  // 流水线阶段1寄存器
  reg [10:0] rx_id_stage1;
  reg [7:0] rx_data_stage1 [0:7];
  reg [3:0] rx_dlc_stage1;
  reg write_en_stage1, read_en_stage1;
  reg [$clog2(BUFFER_DEPTH):0] rd_ptr_stage1, wr_ptr_stage1;
  
  // 流水线阶段2寄存器
  reg [10:0] id_read_stage2;
  reg [7:0] data_read_stage2 [0:7];
  reg [3:0] dlc_read_stage2;
  reg read_valid_stage2;
  
  integer i, j;
  
  // 第一级流水线 - 捕获输入
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_id_stage1 <= 0;
      rx_dlc_stage1 <= 0;
      write_en_stage1 <= 0;
      read_en_stage1 <= 0;
      rd_ptr_stage1 <= 0;
      wr_ptr_stage1 <= 0;
      valid_stage1 <= 0;
      
      for (i = 0; i < 8; i = i + 1) begin
        rx_data_stage1[i] <= 0;
      end
    end else begin
      rx_id_stage1 <= rx_id;
      rx_dlc_stage1 <= rx_dlc;
      write_en_stage1 <= write_en;
      read_en_stage1 <= read_en;
      rd_ptr_stage1 <= rd_ptr;
      wr_ptr_stage1 <= wr_ptr;
      valid_stage1 <= 1;
      
      for (i = 0; i < 8; i = i + 1) begin
        rx_data_stage1[i] <= rx_data[i];
      end
    end
  end
  
  // 第二级流水线 - 处理数据
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // 重置所有缓冲区
      for (i = 0; i < BUFFER_DEPTH; i = i + 1) begin
        id_buffer[i] <= 0;
        dlc_buffer[i] <= 0;
        for (j = 0; j < 8; j = j + 1) begin
          data_buffer[i][j] <= 0;
        end
      end
      
      // 重置读取数据暂存寄存器
      id_read_stage2 <= 0;
      dlc_read_stage2 <= 0;
      read_valid_stage2 <= 0;
      valid_stage2 <= 0;
      
      for (i = 0; i < 8; i = i + 1) begin
        data_read_stage2[i] <= 0;
      end
    end else begin
      valid_stage2 <= valid_stage1;
      read_valid_stage2 <= 0;
      
      // 写入操作 - 在第二级执行
      if (write_en_stage1) begin
        id_buffer[wr_ptr_stage1] <= rx_id_stage1;
        dlc_buffer[wr_ptr_stage1] <= rx_dlc_stage1;
        for (i = 0; i < 8; i = i + 1) begin
          data_buffer[wr_ptr_stage1][i] <= rx_data_stage1[i];
        end
      end
      
      // 读取操作 - 准备数据
      if (read_en_stage1) begin
        id_read_stage2 <= id_buffer[rd_ptr_stage1];
        dlc_read_stage2 <= dlc_buffer[rd_ptr_stage1];
        read_valid_stage2 <= 1;
        for (i = 0; i < 8; i = i + 1) begin
          data_read_stage2[i] <= data_buffer[rd_ptr_stage1][i];
        end
      end
    end
  end
  
  // 第三级流水线 - 输出
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_id <= 0;
      tx_dlc <= 0;
      for (i = 0; i < 8; i = i + 1) begin
        tx_data[i] <= 0;
      end
    end else begin
      // 只有当读取操作有效时才更新输出
      if (read_valid_stage2) begin
        tx_id <= id_read_stage2;
        tx_dlc <= dlc_read_stage2;
        for (i = 0; i < 8; i = i + 1) begin
          tx_data[i] <= data_read_stage2[i];
        end
      end
    end
  end
endmodule