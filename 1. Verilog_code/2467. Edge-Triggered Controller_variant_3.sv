//SystemVerilog
module edge_triggered_intr_ctrl(
  input clk, rst_n,
  input [7:0] intr_in,
  input intr_ack,              // 应答信号，替代原来的ready
  output reg [2:0] intr_num,
  output reg intr_req          // 请求信号，替代原来的valid/pending
);
  reg [7:0] intr_prev;
  wire [7:0] intr_edge;
  reg [7:0] intr_flag;
  reg intr_active;             // 标记中断处理状态
  
  assign intr_edge = intr_in & ~intr_prev;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      intr_prev <= 8'h0;
      intr_flag <= 8'h0;
      intr_num <= 3'h0;
      intr_req <= 1'b0;
      intr_active <= 1'b0;
    end else begin
      intr_prev <= intr_in;
      
      // 当有新中断且当前没有活跃中断时，更新中断标志
      if (!intr_active) begin
        intr_flag <= (intr_flag | intr_edge);
      end
      
      // Req-Ack握手逻辑
      if (!intr_active && |intr_flag) begin
        // 有未处理中断且当前无活跃中断，发出请求
        intr_req <= 1'b1;
        intr_active <= 1'b1;
        
        // 优先级编码
        casez (intr_flag)
          8'b???????1: intr_num <= 3'd0;
          8'b??????10: intr_num <= 3'd1;
          8'b?????100: intr_num <= 3'd2;
          8'b????1000: intr_num <= 3'd3;
          8'b???10000: intr_num <= 3'd4;
          8'b??100000: intr_num <= 3'd5;
          8'b?1000000: intr_num <= 3'd6;
          8'b10000000: intr_num <= 3'd7;
          default: intr_num <= intr_num;
        endcase
      end else if (intr_active && intr_ack) begin
        // 收到应答，清除当前处理的中断标志位
        intr_req <= 1'b0;
        intr_active <= 1'b0;
        intr_flag[intr_num] <= 1'b0; // 清除已处理的中断标志
      end
    end
  end
endmodule