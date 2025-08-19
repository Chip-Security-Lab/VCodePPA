//SystemVerilog
///////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////
// 顶层模块: 中断控制器FIFO
///////////////////////////////////////////////////////////
module fifo_intr_ctrl #(
  parameter FIFO_DEPTH = 8,
  parameter PTR_WIDTH = $clog2(FIFO_DEPTH)
)(
  input clk, rst_n,
  input [7:0] intr_src,
  input pop,
  output [2:0] intr_id,
  output empty, full
);
  
  // 内部连线
  wire [7:0] intr_src_reg;
  wire [7:0] edge_detected;
  wire write_enable;
  wire [2:0] write_data;
  wire [PTR_WIDTH-1:0] wr_ptr, rd_ptr;
  wire [PTR_WIDTH:0] fifo_count;
  
  // 输入寄存
  input_register u_input_register (
    .clk(clk),
    .rst_n(rst_n),
    .intr_src(intr_src),
    .intr_src_reg(intr_src_reg)
  );
  
  // 边沿检测子模块实例化
  edge_detector u_edge_detector (
    .clk(clk),
    .rst_n(rst_n),
    .intr_src(intr_src_reg),
    .edge_detected(edge_detected)
  );
  
  // 优先级编码器子模块实例化
  priority_encoder u_priority_encoder (
    .edge_detected(edge_detected),
    .write_enable(write_enable),
    .write_data(write_data)
  );
  
  // FIFO存储器子模块实例化
  fifo_memory #(
    .FIFO_DEPTH(FIFO_DEPTH),
    .PTR_WIDTH(PTR_WIDTH)
  ) u_fifo_memory (
    .clk(clk),
    .rst_n(rst_n),
    .write_enable(write_enable),
    .write_data(write_data),
    .pop(pop),
    .full(full),
    .intr_id(intr_id),
    .wr_ptr(wr_ptr),
    .rd_ptr(rd_ptr),
    .fifo_count(fifo_count)
  );
  
  // FIFO状态控制器子模块实例化
  fifo_status_controller #(
    .FIFO_DEPTH(FIFO_DEPTH),
    .PTR_WIDTH(PTR_WIDTH)
  ) u_fifo_status_controller (
    .fifo_count(fifo_count),
    .empty(empty),
    .full(full)
  );
  
endmodule

///////////////////////////////////////////////////////////
// 输入寄存器模块
///////////////////////////////////////////////////////////
module input_register (
  input clk,
  input rst_n,
  input [7:0] intr_src,
  output reg [7:0] intr_src_reg
);
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      intr_src_reg <= 8'h0;
    end else begin
      intr_src_reg <= intr_src;
    end
  end
  
endmodule

///////////////////////////////////////////////////////////
// 边沿检测器子模块
///////////////////////////////////////////////////////////
module edge_detector (
  input clk,
  input rst_n,
  input [7:0] intr_src,
  output reg [7:0] edge_detected
);
  
  reg [7:0] prev_src;
  wire [7:0] edge_detect_comb;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      prev_src <= 8'h0;
      edge_detected <= 8'h0;
    end else begin
      prev_src <= intr_src;
      edge_detected <= edge_detect_comb;
    end
  end
  
  // 上升沿检测组合逻辑
  assign edge_detect_comb = intr_src & ~prev_src;
  
endmodule

///////////////////////////////////////////////////////////
// 优先级编码器子模块
///////////////////////////////////////////////////////////
module priority_encoder (
  input [7:0] edge_detected,
  output reg write_enable,
  output reg [2:0] write_data
);
  
  always @(*) begin
    write_enable = |edge_detected;
    
    // 根据检测到的边沿确定中断ID
    if (edge_detected[0]) begin
      write_data = 3'd0;
    end else if (edge_detected[1]) begin
      write_data = 3'd1;
    end else if (edge_detected[2]) begin
      write_data = 3'd2;
    end else if (edge_detected[3]) begin
      write_data = 3'd3;
    end else if (edge_detected[4]) begin
      write_data = 3'd4;
    end else if (edge_detected[5]) begin
      write_data = 3'd5;
    end else if (edge_detected[6]) begin
      write_data = 3'd6;
    end else if (edge_detected[7]) begin
      write_data = 3'd7;
    end else begin
      write_data = 3'd0;
    end
  end
  
endmodule

///////////////////////////////////////////////////////////
// FIFO内存子模块
///////////////////////////////////////////////////////////
module fifo_memory #(
  parameter FIFO_DEPTH = 8,
  parameter PTR_WIDTH = $clog2(FIFO_DEPTH)
)(
  input clk,
  input rst_n,
  input write_enable,
  input [2:0] write_data,
  input pop,
  input full,
  output reg [2:0] intr_id,
  output reg [PTR_WIDTH-1:0] wr_ptr, rd_ptr,
  output reg [PTR_WIDTH:0] fifo_count
);
  
  // FIFO存储器
  reg [2:0] fifo [0:FIFO_DEPTH-1];
  integer i;
  
  // 组合逻辑信号
  reg [PTR_WIDTH-1:0] next_wr_ptr, next_rd_ptr;
  reg [PTR_WIDTH:0] next_fifo_count;
  reg [2:0] next_intr_id;
  
  // 计算下一个状态
  always @(*) begin
    next_wr_ptr = wr_ptr;
    next_rd_ptr = rd_ptr;
    next_fifo_count = fifo_count;
    next_intr_id = intr_id;
    
    // 写入逻辑
    if (write_enable && !full) begin
      if (wr_ptr == FIFO_DEPTH-1) begin
        next_wr_ptr = {PTR_WIDTH{1'b0}};
      end else begin
        next_wr_ptr = wr_ptr + 1'b1;
      end
      next_fifo_count = fifo_count + 1'b1;
    end
    
    // 读取逻辑
    if (pop && (fifo_count > 0)) begin
      next_intr_id = fifo[rd_ptr];
      if (rd_ptr == FIFO_DEPTH-1) begin
        next_rd_ptr = {PTR_WIDTH{1'b0}};
      end else begin
        next_rd_ptr = rd_ptr + 1'b1;
      end
      next_fifo_count = fifo_count - 1'b1;
    end
  end
  
  // 寄存状态更新
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr <= {PTR_WIDTH{1'b0}};
      rd_ptr <= {PTR_WIDTH{1'b0}};
      fifo_count <= {(PTR_WIDTH+1){1'b0}};
      intr_id <= 3'h0;
      
      for (i = 0; i < FIFO_DEPTH; i = i + 1)
        fifo[i] <= 3'h0;
    end else begin
      // 更新FIFO存储器
      if (write_enable && !full) begin
        fifo[wr_ptr] <= write_data;
      end
      
      // 更新指针和计数
      wr_ptr <= next_wr_ptr;
      rd_ptr <= next_rd_ptr;
      fifo_count <= next_fifo_count;
      intr_id <= next_intr_id;
    end
  end
  
endmodule

///////////////////////////////////////////////////////////
// FIFO状态控制器子模块
///////////////////////////////////////////////////////////
module fifo_status_controller #(
  parameter FIFO_DEPTH = 8,
  parameter PTR_WIDTH = $clog2(FIFO_DEPTH)
)(
  input [PTR_WIDTH:0] fifo_count,
  output reg empty,
  output reg full
);
  
  // FIFO状态信号寄存
  always @(*) begin
    if (fifo_count == 0) begin
      empty = 1'b1;
    end else begin
      empty = 1'b0;
    end
    
    if (fifo_count == FIFO_DEPTH) begin
      full = 1'b1;
    end else begin
      full = 1'b0;
    end
  end
  
endmodule