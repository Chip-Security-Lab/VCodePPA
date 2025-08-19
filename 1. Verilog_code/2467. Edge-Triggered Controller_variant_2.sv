//SystemVerilog
module edge_triggered_intr_ctrl(
  input clk, rst_n,
  input [7:0] intr_in,
  output reg [2:0] intr_num,
  output reg intr_pending
);
  reg [7:0] intr_prev;
  wire [7:0] intr_edge;
  reg [7:0] intr_flag;
  
  // 使用位操作检测上升沿
  assign intr_edge = intr_in & ~intr_prev;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      intr_prev <= 8'h0;
      intr_flag <= 8'h0;
      intr_num <= 3'h0;
      intr_pending <= 1'b0;
    end else begin
      intr_prev <= intr_in;
      
      // 更新中断标志和挂起状态
      if (intr_edge) begin
        intr_flag <= intr_flag | intr_edge;
        intr_pending <= 1'b1;
      end
      
      // 使用优先编码器处理中断优先级
      if (|intr_flag) begin
        casez (intr_flag)
          8'b????_???1: begin intr_num <= 3'd0; intr_flag[0] <= 1'b0; end
          8'b????_??10: begin intr_num <= 3'd1; intr_flag[1] <= 1'b0; end
          8'b????_?100: begin intr_num <= 3'd2; intr_flag[2] <= 1'b0; end
          8'b????_1000: begin intr_num <= 3'd3; intr_flag[3] <= 1'b0; end
          8'b???1_0000: begin intr_num <= 3'd4; intr_flag[4] <= 1'b0; end
          8'b??10_0000: begin intr_num <= 3'd5; intr_flag[5] <= 1'b0; end
          8'b?100_0000: begin intr_num <= 3'd6; intr_flag[6] <= 1'b0; end
          8'b1000_0000: begin intr_num <= 3'd7; intr_flag[7] <= 1'b0; end
          default: begin /* 保持现有状态 */ end
        endcase
        
        // 更新intr_pending状态
        intr_pending <= |intr_flag;
      end
    end
  end
endmodule