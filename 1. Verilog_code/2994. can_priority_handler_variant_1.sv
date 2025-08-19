//SystemVerilog
module can_priority_handler #(
  parameter NUM_BUFFERS = 4
)(
  input wire clk, rst_n,
  input wire [10:0] msg_id [0:NUM_BUFFERS-1],
  input wire [NUM_BUFFERS-1:0] buffer_ready,
  output reg [NUM_BUFFERS-1:0] buffer_select,
  output reg transmit_request
);
  reg [10:0] highest_priority_id;
  reg [$clog2(NUM_BUFFERS)-1:0] highest_priority_idx;
  integer i;
  
  // 桶形移位器实现变量移位操作
  function [NUM_BUFFERS-1:0] barrel_shift;
    input [$clog2(NUM_BUFFERS)-1:0] shift_amount;
    begin
      barrel_shift = 1'b1;
      
      // 第一级移位 - 移动1位
      if (shift_amount[0])
        barrel_shift = {barrel_shift[NUM_BUFFERS-2:0], barrel_shift[NUM_BUFFERS-1]};
        
      // 第二级移位 - 移动2位
      if (NUM_BUFFERS > 2 && shift_amount[1])
        barrel_shift = {barrel_shift[NUM_BUFFERS-3:0], barrel_shift[NUM_BUFFERS-1:NUM_BUFFERS-2]};
        
      // 第三级移位 - 移动4位
      if (NUM_BUFFERS > 4 && shift_amount[2])
        barrel_shift = {barrel_shift[NUM_BUFFERS-5:0], barrel_shift[NUM_BUFFERS-1:NUM_BUFFERS-4]};
        
      // 第四级移位 - 移动8位
      if (NUM_BUFFERS > 8 && shift_amount[3])
        barrel_shift = {barrel_shift[NUM_BUFFERS-9:0], barrel_shift[NUM_BUFFERS-1:NUM_BUFFERS-8]};
    end
  endfunction
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      buffer_select <= 0;
      transmit_request <= 0;
      highest_priority_id <= 11'h7FF;
      highest_priority_idx <= 0;
    end else begin
      // Find buffer with lowest ID (highest priority)
      highest_priority_id <= 11'h7FF; // Lowest priority
      highest_priority_idx <= 0;
      
      for (i = 0; i < NUM_BUFFERS; i = i + 1) begin
        if (buffer_ready[i] && msg_id[i] < highest_priority_id) begin
          highest_priority_id <= msg_id[i];
          highest_priority_idx <= i;
        end
      end
      
      // 使用桶形移位器生成buffer_select信号
      buffer_select <= (buffer_ready != 0) ? barrel_shift(highest_priority_idx) : 0;
      transmit_request <= (buffer_ready != 0);
    end
  end
endmodule