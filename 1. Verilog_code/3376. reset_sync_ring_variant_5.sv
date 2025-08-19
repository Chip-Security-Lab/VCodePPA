//SystemVerilog
// 顶层模块
module reset_sync_ring (
  input  wire clk,
  input  wire rst_n,
  output wire out_rst
);
  // 内部连接信号
  wire [3:0] ring_state;
  reg  [3:0] ring_state_buf1, ring_state_buf2;
  wire       clk_buf1, clk_buf2;
  wire       rst_n_buf1, rst_n_buf2;
  wire       out_rst_internal;
  reg        out_rst_buf;
  
  // 时钟和复位缓冲
  BUFG clk_buffer1 (.I(clk), .O(clk_buf1));
  BUFG clk_buffer2 (.I(clk_buf1), .O(clk_buf2));
  
  BUFG rst_buffer1 (.I(rst_n), .O(rst_n_buf1));
  BUFG rst_buffer2 (.I(rst_n_buf1), .O(rst_n_buf2));
  
  // 实例化环形移位寄存器子模块
  ring_register ring_reg_inst (
    .clk      (clk_buf1),
    .rst_n    (rst_n_buf1),
    .ring_out (ring_state)
  );
  
  // 为高扇出的ring_state添加缓冲寄存器
  always @(posedge clk_buf1 or negedge rst_n_buf1) begin
    if (!rst_n_buf1)
      ring_state_buf1 <= 4'b1000;
    else
      ring_state_buf1 <= ring_state;
  end
  
  always @(posedge clk_buf2 or negedge rst_n_buf2) begin
    if (!rst_n_buf2)
      ring_state_buf2 <= 4'b1000;
    else
      ring_state_buf2 <= ring_state_buf1;
  end
  
  // 实例化输出选择子模块
  output_selector out_sel_inst (
    .ring_state (ring_state_buf1),
    .out_rst    (out_rst_internal)
  );
  
  // 为输出添加缓冲寄存器
  always @(posedge clk_buf2 or negedge rst_n_buf2) begin
    if (!rst_n_buf2)
      out_rst_buf <= 1'b0;
    else
      out_rst_buf <= out_rst_internal;
  end
  
  assign out_rst = out_rst_buf;
  
endmodule

// 环形移位寄存器子模块
module ring_register (
  input  wire       clk,
  input  wire       rst_n,
  output reg  [3:0] ring_out
);
  reg [3:0] ring_out_next;
  
  // 计算下一个状态
  always @(*) begin
    ring_out_next = {ring_out[2:0], ring_out[3]};
  end
  
  // 寄存器更新
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      ring_out <= 4'b1000;
    else
      ring_out <= ring_out_next;
  end
endmodule

// 输出选择子模块
module output_selector (
  input  wire [3:0] ring_state,
  output wire       out_rst
);
  assign out_rst = ring_state[0];
endmodule

// 缓冲器模块
module BUFG (
  input  wire I,
  output wire O
);
  assign O = I;
endmodule