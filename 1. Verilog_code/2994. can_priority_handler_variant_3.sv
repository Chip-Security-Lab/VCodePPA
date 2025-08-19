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
  // 注册输入信号，将寄存器前移
  reg [10:0] msg_id_reg [0:NUM_BUFFERS-1];
  reg [NUM_BUFFERS-1:0] buffer_ready_reg;
  
  // 组合逻辑信号 - 计算优先级
  reg [10:0] highest_priority_id_comb;
  reg [$clog2(NUM_BUFFERS)-1:0] highest_priority_idx_comb;
  reg any_buffer_ready_comb;
  
  // 输出逻辑信号
  reg [NUM_BUFFERS-1:0] buffer_select_comb;
  reg transmit_request_comb;
  
  integer i;
  
  // 寄存输入信号
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (i = 0; i < NUM_BUFFERS; i = i + 1) begin
        msg_id_reg[i] <= 11'h7FF;
      end
      buffer_ready_reg <= 0;
    end else begin
      for (i = 0; i < NUM_BUFFERS; i = i + 1) begin
        msg_id_reg[i] <= msg_id[i];
      end
      buffer_ready_reg <= buffer_ready;
    end
  end
  
  // 组合逻辑计算优先级 - 使用寄存的输入信号
  always @(*) begin
    highest_priority_id_comb = 11'h7FF; // 最低优先级
    highest_priority_idx_comb = 0;
    any_buffer_ready_comb = (buffer_ready_reg != 0);
    
    for (i = 0; i < NUM_BUFFERS; i = i + 1) begin
      if (buffer_ready_reg[i] && msg_id_reg[i] < highest_priority_id_comb) begin
        highest_priority_id_comb = msg_id_reg[i];
        highest_priority_idx_comb = i;
      end
    end
    
    // 直接生成输出组合逻辑，移除中间寄存阶段
    buffer_select_comb = any_buffer_ready_comb ? (1 << highest_priority_idx_comb) : 0;
    transmit_request_comb = any_buffer_ready_comb;
  end
  
  // 寄存输出信号
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      buffer_select <= 0;
      transmit_request <= 0;
    end else begin
      buffer_select <= buffer_select_comb;
      transmit_request <= transmit_request_comb;
    end
  end
endmodule