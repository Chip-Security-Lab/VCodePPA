//SystemVerilog
module reset_propagation_monitor (
  input wire clk,
  input wire reset_src,
  input wire [3:0] reset_dst,
  output reg propagation_error
);
  // 寄存器声明
  reg reset_src_d;
  reg [7:0] timeout;
  reg checking;
  
  // 组合逻辑信号声明
  wire reset_edge_detected;
  wire all_resets_propagated;
  wire timeout_reached;
  
  // 组合逻辑模块实例化
  reset_condition_detector condition_detector (
    .reset_src(reset_src),
    .reset_src_d(reset_src_d),
    .reset_dst(reset_dst),
    .timeout(timeout),
    .reset_edge_detected(reset_edge_detected),
    .all_resets_propagated(all_resets_propagated),
    .timeout_reached(timeout_reached)
  );
  
  // 时序逻辑 - 状态更新
  always @(posedge clk) begin
    // 输入信号采样
    reset_src_d <= reset_src;
    
    // 状态更新逻辑
    if (reset_edge_detected) begin
      checking <= 1'b1;
      timeout <= 8'd0;
      propagation_error <= 1'b0;
    end 
    else if (checking) begin
      // 递增计数器
      timeout <= timeout + 8'd1;
      
      // 状态转换逻辑
      if (all_resets_propagated || timeout_reached) begin
        checking <= 1'b0;
        if (timeout_reached) begin
          propagation_error <= 1'b1;
        end
      end
    end
  end
endmodule

// 组合逻辑模块 - 检测条件
module reset_condition_detector (
  input wire reset_src,
  input wire reset_src_d,
  input wire [3:0] reset_dst,
  input wire [7:0] timeout,
  output wire reset_edge_detected,
  output wire all_resets_propagated,
  output wire timeout_reached
);
  // 纯组合逻辑使用assign语句
  assign reset_edge_detected = reset_src && !reset_src_d;
  assign all_resets_propagated = &reset_dst;
  assign timeout_reached = (timeout == 8'hFF);
endmodule