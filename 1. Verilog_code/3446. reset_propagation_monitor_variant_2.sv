//SystemVerilog
module reset_propagation_monitor (
  input wire clk,
  input wire reset_valid,     // Changed from reset_src to reset_valid
  input wire [3:0] reset_dst,
  input wire dst_ready,       // Added ready signal from destination
  output reg propagation_error
);
  reg reset_valid_d;
  reg [7:0] timeout;
  reg checking;
  
  // 检测reset_valid上升沿的逻辑
  wire reset_edge = reset_valid && !reset_valid_d;
  // 优化的复位完成检测
  wire reset_complete = &reset_dst;
  // 优化的超时检测
  wire timeout_reached = (timeout == 8'hFE);
  // 有效的握手检测
  wire valid_handshake = reset_valid && dst_ready;
  
  always @(posedge clk) begin
    // 寄存reset_valid用于边沿检测
    reset_valid_d <= reset_valid;
    
    if (reset_edge && dst_ready) begin
      // 复位边沿检测到且目标准备好，启动检查
      checking <= 1'b1;
      timeout <= 8'd0;
      propagation_error <= 1'b0;
    end 
    else if (checking) begin
      // 只有在有效握手时增加超时计数器
      if (valid_handshake)
        timeout <= timeout + 8'd1;
      
      // 状态转换逻辑优化
      if (reset_complete || timeout_reached) begin
        // 当复位完成或超时时，停止检查
        checking <= 1'b0;
        // 只在超时情况下设置错误标志
        if (timeout_reached)
          propagation_error <= 1'b1;
      end
    end
  end
endmodule