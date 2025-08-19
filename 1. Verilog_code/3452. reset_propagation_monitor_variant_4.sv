//SystemVerilog
// 顶层模块
module reset_propagation_monitor (
  input  wire clk,
  input  wire reset_src,
  input  wire [3:0] reset_dst,
  output wire propagation_error
);
  // 内部信号连接
  wire reset_src_edge_detected;
  wire reset_dst_all_asserted;
  wire timeout_reached;
  wire checking;
  wire [7:0] timeout;

  // 子模块实例化
  edge_detector u_edge_detector (
    .clk                  (clk),
    .reset_src            (reset_src),
    .reset_src_edge_detected (reset_src_edge_detected)
  );

  reset_status_monitor u_reset_status_monitor (
    .clk                  (clk),
    .reset_dst            (reset_dst),
    .reset_dst_all_asserted (reset_dst_all_asserted)
  );

  timeout_controller u_timeout_controller (
    .clk                  (clk),
    .timeout              (timeout),
    .timeout_reached      (timeout_reached)
  );

  propagation_controller u_propagation_controller (
    .clk                  (clk),
    .reset_src_edge_detected (reset_src_edge_detected),
    .reset_dst_all_asserted  (reset_dst_all_asserted),
    .timeout_reached      (timeout_reached),
    .checking             (checking),
    .timeout              (timeout),
    .propagation_error    (propagation_error)
  );

endmodule

// 边缘检测子模块
module edge_detector (
  input  wire clk,
  input  wire reset_src,
  output reg  reset_src_edge_detected
);
  // 寄存器声明
  reg reset_src_d1, reset_src_d2;

  // 检测reset_src上升沿
  always @(posedge clk) begin
    reset_src_d1 <= reset_src;
    reset_src_d2 <= reset_src_d1;
    
    // 检测上升沿
    reset_src_edge_detected <= reset_src_d1 && !reset_src_d2;
  end
endmodule

// 复位状态监控子模块
module reset_status_monitor (
  input  wire clk,
  input  wire [3:0] reset_dst,
  output reg  reset_dst_all_asserted
);
  // 寄存器声明
  reg [3:0] reset_dst_pipe;

  // 采样并检查所有reset_dst位是否被置位
  always @(posedge clk) begin
    reset_dst_pipe <= reset_dst;
    reset_dst_all_asserted <= &reset_dst_pipe;
  end
endmodule

// 超时控制子模块
module timeout_controller (
  input  wire clk,
  input  wire [7:0] timeout,
  output reg  timeout_reached
);
  // 检查超时计数器是否达到最大值
  always @(posedge clk) begin
    timeout_reached <= (timeout == 8'hFF);
  end
endmodule

// 传播控制子模块
module propagation_controller (
  input  wire clk,
  input  wire reset_src_edge_detected,
  input  wire reset_dst_all_asserted,
  input  wire timeout_reached,
  output reg  checking,
  output reg  [7:0] timeout,
  output reg  propagation_error
);
  // 状态机和计数器
  always @(posedge clk) begin
    if (reset_src_edge_detected) begin
      checking <= 1'b1;
      timeout <= 8'd0;
      propagation_error <= 1'b0;
    end else if (checking) begin
      timeout <= timeout + 1;
      
      if (reset_dst_all_asserted)
        checking <= 1'b0;
      else if (timeout_reached) begin
        propagation_error <= 1'b1;
        checking <= 1'b0;
      end
    end
  end
endmodule