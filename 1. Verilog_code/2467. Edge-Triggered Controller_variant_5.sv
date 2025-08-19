//SystemVerilog
module edge_triggered_intr_ctrl(
  input clk, rst_n,
  input [7:0] intr_in,
  output reg [2:0] intr_num,
  input intr_ack,
  output reg intr_req
);
  reg [7:0] intr_prev;
  reg [7:0] intr_flag;
  wire [7:0] intr_edge;
  reg [2:0] priority_num;
  reg intr_in_process;
  
  // 检测中断上升沿
  assign intr_edge = intr_in & ~intr_prev;
  
  // 优先级编码器使用always块实现，替代条件运算符链
  always @(*) begin
    if (intr_flag[0]) begin
      priority_num = 3'd0;
    end else if (intr_flag[1]) begin
      priority_num = 3'd1;
    end else if (intr_flag[2]) begin
      priority_num = 3'd2;
    end else if (intr_flag[3]) begin
      priority_num = 3'd3;
    end else if (intr_flag[4]) begin
      priority_num = 3'd4;
    end else if (intr_flag[5]) begin
      priority_num = 3'd5;
    end else if (intr_flag[6]) begin
      priority_num = 3'd6;
    end else if (intr_flag[7]) begin
      priority_num = 3'd7;
    end else begin
      priority_num = 3'd0;
    end
  end
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      intr_prev <= 8'h0;
      intr_flag <= 8'h0;
      intr_num <= 3'h0;
      intr_req <= 1'b0;
      intr_in_process <= 1'b0;
    end else begin
      // 保存前一个周期的中断值
      intr_prev <= intr_in;
      
      // 更新中断标志和请求状态
      if (!intr_in_process) begin
        // 检测新的中断边沿
        if (intr_edge != 8'h0) begin
          intr_flag <= intr_flag | intr_edge;
        end
        
        // 生成新的中断请求
        if ((intr_flag != 8'h0) && !intr_req) begin
          intr_req <= 1'b1;
          intr_num <= priority_num;
          intr_in_process <= 1'b1;
        end
      end else begin
        // 处理中断确认
        if (intr_ack) begin
          intr_req <= 1'b0;
          intr_flag[priority_num] <= 1'b0;
          intr_in_process <= 1'b0;
        end
      end
      
      // 所有中断处理完成且没有新请求
      if (intr_flag == 8'h0 && !intr_in_process) begin
        intr_req <= 1'b0;
      end
    end
  end
endmodule