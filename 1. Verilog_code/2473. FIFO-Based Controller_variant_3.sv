//SystemVerilog
module fifo_intr_ctrl #(
  parameter FIFO_DEPTH = 8,
  parameter PTR_WIDTH = $clog2(FIFO_DEPTH)
)(
  input  logic        clk,      // 系统时钟
  input  logic        rst_n,    // 低电平有效复位
  input  logic [7:0]  intr_src, // 中断源
  input  logic        pop,      // 弹出信号
  output logic [2:0]  intr_id,  // 中断ID
  output logic        empty,    // FIFO空标志
  output logic        full      // FIFO满标志
);
  // 内部存储和指针
  logic [2:0]          fifo [0:FIFO_DEPTH-1];
  logic [PTR_WIDTH-1:0] wr_ptr, rd_ptr;
  logic [PTR_WIDTH:0]   count;
  
  // 中断检测逻辑
  logic [7:0] prev_src;
  logic [7:0] edge_detect;
  
  // 指针更新和溢出检测信号
  logic [PTR_WIDTH-1:0] next_wr_ptr, next_rd_ptr;
  logic                 wr_wrap, rd_wrap;
  
  // 计数器控制信号
  logic count_incr, count_decr;
  logic [PTR_WIDTH:0] next_count;
  
  // 寄存信号声明 - 分割数据路径
  logic write_valid;
  logic [2:0] write_data;
  logic read_valid;
  
  // ===== 阶段1: 边沿检测逻辑 =====
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      prev_src <= 8'h0;
    end else begin
      prev_src <= intr_src;
    end
  end
  
  assign edge_detect = intr_src & ~prev_src;
  
  // ===== 阶段2: 优先级编码器 - 确定写入数据 =====
  always_comb begin
    write_valid = |edge_detect;
    write_data = 3'h0;
    
    // 简化的优先级编码逻辑
    if (edge_detect[0]) write_data = 3'd0;
    else if (edge_detect[1]) write_data = 3'd1;
    else if (edge_detect[2]) write_data = 3'd2;
    else if (edge_detect[3]) write_data = 3'd3;
    else if (edge_detect[4]) write_data = 3'd4;
    else if (edge_detect[5]) write_data = 3'd5;
    else if (edge_detect[6]) write_data = 3'd6;
    else if (edge_detect[7]) write_data = 3'd7;
  end
  
  // ===== 阶段3: FIFO控制逻辑 =====
  // 状态标志 - 清晰地表示FIFO状态
  assign empty = (count == 0);
  assign full = (count == FIFO_DEPTH);
  
  // 指针环绕逻辑 - 分离出复杂路径
  assign wr_wrap = (wr_ptr == FIFO_DEPTH-1);
  assign rd_wrap = (rd_ptr == FIFO_DEPTH-1);
  assign next_wr_ptr = wr_wrap ? '0 : wr_ptr + 1'b1;
  assign next_rd_ptr = rd_wrap ? '0 : rd_ptr + 1'b1;
  
  // 有效的读写操作
  assign count_incr = write_valid && !full;
  assign count_decr = pop && !empty;
  assign read_valid = pop && !empty;
  
  // ===== 阶段4: 计数器逻辑实现 =====
  always_comb begin
    case ({count_incr, count_decr})
      2'b10:   next_count = count + 1'b1; // 仅写入
      2'b01:   next_count = count - 1'b1; // 仅读取
      default: next_count = count;        // 无操作或同时读写
    endcase
  end
  
  // ===== 阶段5: FIFO存储器控制和更新 =====
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // 复位所有状态
      count  <= '0;
      wr_ptr <= '0;
      rd_ptr <= '0;
      intr_id <= 3'h0;
      for (int i = 0; i < FIFO_DEPTH; i++) begin
        fifo[i] <= 3'h0;
      end
    end else begin
      // 写入逻辑
      if (count_incr) begin
        fifo[wr_ptr] <= write_data;
        wr_ptr <= next_wr_ptr;
      end
      
      // 读取逻辑
      if (read_valid) begin
        intr_id <= fifo[rd_ptr];
        rd_ptr <= next_rd_ptr;
      end
      
      // 计数器更新
      count <= next_count;
    end
  end
  
endmodule