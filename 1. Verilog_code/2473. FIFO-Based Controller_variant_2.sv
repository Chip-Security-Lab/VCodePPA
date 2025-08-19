//SystemVerilog
module fifo_intr_ctrl #(
  parameter FIFO_DEPTH = 8,
  parameter PTR_WIDTH = $clog2(FIFO_DEPTH)
)(
  input clk, rst_n,
  input [7:0] intr_src,
  input pop,
  output reg [2:0] intr_id,
  output empty, full
);
  reg [2:0] fifo [0:FIFO_DEPTH-1];
  reg [PTR_WIDTH-1:0] wr_ptr, rd_ptr;
  reg [PTR_WIDTH:0] count;
  integer i;
  
  wire [7:0] edge_detect;
  reg [7:0] prev_src;
  reg [2:0] next_intr_id;
  
  // Fan-out buffer registers
  reg pop_r, pop_r1, pop_r2;
  reg empty_r, full_r;
  reg [PTR_WIDTH:0] count_buf1, count_buf2;
  reg [PTR_WIDTH-1:0] rd_ptr_buf;
  reg [7:0] edge_detect_buf1, edge_detect_buf2;
  
  // Edge detection logic with reduced fan-out
  assign edge_detect = intr_src & ~prev_src;
  
  // Buffer registers for high fan-out signals
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pop_r <= 1'b0;
      pop_r1 <= 1'b0;
      pop_r2 <= 1'b0;
      count_buf1 <= 0;
      count_buf2 <= 0;
      rd_ptr_buf <= 0;
      edge_detect_buf1 <= 8'h0;
      edge_detect_buf2 <= 8'h0;
    end else begin
      pop_r <= pop;
      pop_r1 <= pop_r;
      pop_r2 <= pop_r1;
      count_buf1 <= count;
      count_buf2 <= count_buf1;
      rd_ptr_buf <= rd_ptr;
      edge_detect_buf1 <= edge_detect;
      edge_detect_buf2 <= edge_detect_buf1;
    end
  end
  
  // 预计算下一个中断ID，实现后向寄存器重定时
  always @(*) begin
    next_intr_id = intr_id;
    if (!empty_r && pop_r) begin
      next_intr_id = fifo[rd_ptr_buf];
    end
  end
  
  // Buffered status outputs
  assign empty = empty_r;
  assign full = full_r;
  
  // Main state machine with reduced fan-out
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr <= 0;
      rd_ptr <= 0;
      count <= 0;
      prev_src <= 8'h0;
      empty_r <= 1'b1;
      full_r <= 1'b0;
      
      for (i = 0; i < FIFO_DEPTH; i = i + 1)
        fifo[i] <= 3'h0;
    end else begin
      prev_src <= intr_src;
      
      // 在时钟沿更新状态信号 - using buffered signals to reduce fan-out
      empty_r <= (count == 0) || (count == 1 && pop_r && !edge_detect_buf1[0]);
      full_r <= (count == FIFO_DEPTH) || (count == FIFO_DEPTH-1 && |edge_detect_buf1 && !pop_r);
      
      // Edge detection and FIFO write - split processing across multiple groups to balance loads
      for (i = 0; i < 4; i = i + 1) begin
        if (edge_detect[i] && !full_r) begin
          fifo[wr_ptr] <= i[2:0];
          wr_ptr <= (wr_ptr == FIFO_DEPTH-1) ? 0 : wr_ptr + 1;
          count <= count + 1;
        end
      end
      
      for (i = 4; i < 8; i = i + 1) begin
        if (edge_detect[i] && !full_r) begin
          fifo[wr_ptr] <= i[2:0];
          wr_ptr <= (wr_ptr == FIFO_DEPTH-1) ? 0 : wr_ptr + 1;
          count <= count + 1;
        end
      end
      
      // FIFO read on pop signal - using buffered pop signal
      if (pop_r && !empty_r) begin
        rd_ptr <= (rd_ptr == FIFO_DEPTH-1) ? 0 : rd_ptr + 1;
        count <= count - 1;
      end
    end
  end
  
  // 后向重定时：将intr_id的更新移动到单独的always块中
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      intr_id <= 3'h0;
    end else begin
      intr_id <= next_intr_id;
    end
  end
endmodule