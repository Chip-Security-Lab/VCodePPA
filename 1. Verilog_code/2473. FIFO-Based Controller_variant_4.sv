//SystemVerilog
module fifo_intr_ctrl #(
  parameter FIFO_DEPTH = 8,
  parameter PTR_WIDTH = $clog2(FIFO_DEPTH)
)(
  input wire clk, 
  input wire rst_n,
  input wire [7:0] intr_src,
  input wire pop,
  output reg [2:0] intr_id,
  output wire empty, 
  output wire full
);
  reg [2:0] fifo [0:FIFO_DEPTH-1];
  reg [PTR_WIDTH-1:0] wr_ptr, rd_ptr;
  reg [PTR_WIDTH:0] count;
  integer i;
  
  wire [7:0] edge_detect;
  reg [7:0] prev_src;
  
  // 使用跳跃进位加法器组件信号
  wire [PTR_WIDTH-1:0] wr_ptr_next;
  wire [PTR_WIDTH-1:0] rd_ptr_next;
  wire [PTR_WIDTH:0] count_inc, count_dec;
  
  // 针对计数器的跳跃进位加法器信号
  wire [PTR_WIDTH:0] p_count, g_count;
  wire [PTR_WIDTH:0] c_count;
  
  // 针对写指针的跳跃进位加法器信号
  wire [PTR_WIDTH-1:0] p_wr, g_wr;
  wire [PTR_WIDTH-1:0] c_wr;
  
  // 针对读指针的跳跃进位加法器信号
  wire [PTR_WIDTH-1:0] p_rd, g_rd;
  wire [PTR_WIDTH-1:0] c_rd;
  
  assign edge_detect = intr_src & ~prev_src;
  assign empty = (count == 0);
  assign full = (count == FIFO_DEPTH);
  
  // 写指针跳跃进位加法器逻辑
  assign p_wr = wr_ptr ^ {{(PTR_WIDTH-1){1'b0}}, 1'b1};
  assign g_wr = wr_ptr & {{(PTR_WIDTH-1){1'b0}}, 1'b1};
  
  generate
    if (PTR_WIDTH > 1) begin: gen_wr_carry
      assign c_wr[0] = g_wr[0];
      for (genvar j = 1; j < PTR_WIDTH; j = j + 1) begin
        assign c_wr[j] = g_wr[j] | (p_wr[j] & c_wr[j-1]);
      end
    end
  endgenerate
  
  assign wr_ptr_next = (wr_ptr == FIFO_DEPTH-1) ? {PTR_WIDTH{1'b0}} :
                       (p_wr ^ {c_wr[PTR_WIDTH-2:0], 1'b0});
  
  // 读指针跳跃进位加法器逻辑
  assign p_rd = rd_ptr ^ {{(PTR_WIDTH-1){1'b0}}, 1'b1};
  assign g_rd = rd_ptr & {{(PTR_WIDTH-1){1'b0}}, 1'b1};
  
  generate
    if (PTR_WIDTH > 1) begin: gen_rd_carry
      assign c_rd[0] = g_rd[0];
      for (genvar j = 1; j < PTR_WIDTH; j = j + 1) begin
        assign c_rd[j] = g_rd[j] | (p_rd[j] & c_rd[j-1]);
      end
    end
  endgenerate
  
  assign rd_ptr_next = (rd_ptr == FIFO_DEPTH-1) ? {PTR_WIDTH{1'b0}} :
                       (p_rd ^ {c_rd[PTR_WIDTH-2:0], 1'b0});
  
  // 计数器跳跃进位加法器逻辑（增加计数）
  assign p_count = count ^ {{PTR_WIDTH{1'b0}}, 1'b1};
  assign g_count = count & {{PTR_WIDTH{1'b0}}, 1'b1};
  
  generate
    if (PTR_WIDTH > 0) begin: gen_count_carry
      assign c_count[0] = g_count[0];
      for (genvar j = 1; j <= PTR_WIDTH; j = j + 1) begin
        assign c_count[j] = g_count[j] | (p_count[j] & c_count[j-1]);
      end
    end
  endgenerate
  
  assign count_inc = p_count ^ {c_count[PTR_WIDTH-1:0], 1'b0};
  assign count_dec = count - 1; // 简单减法，FIFO深度通常较小
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr <= 0;
      rd_ptr <= 0;
      count <= 0;
      prev_src <= 8'h0;
      intr_id <= 3'h0;
      for (i = 0; i < FIFO_DEPTH; i = i + 1)
        fifo[i] <= 3'h0;
    end 
    else begin
      prev_src <= intr_src;
      
      // Edge detection and FIFO write
      for (i = 0; i < 8; i = i + 1) begin
        if (edge_detect[i] && !full) begin
          fifo[wr_ptr] <= i[2:0];
          wr_ptr <= wr_ptr_next;
          count <= count_inc;
        end
      end
      
      // FIFO read on pop signal
      if (pop && !empty) begin
        intr_id <= fifo[rd_ptr];
        rd_ptr <= rd_ptr_next;
        count <= count_dec;
      end
    end
  end
endmodule