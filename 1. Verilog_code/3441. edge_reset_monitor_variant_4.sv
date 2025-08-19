//SystemVerilog
`timescale 1ns/1ps

module edge_reset_monitor (
  input  wire clk,
  input  wire reset_n,
  output wire reset_edge_detected
);
  
  wire reset_n_delayed;
  
  // 实例化重置信号处理单元
  reset_signal_processor proc_inst (
    .clk                (clk),
    .reset_n            (reset_n),
    .reset_n_delayed    (reset_n_delayed),
    .reset_edge_detected(reset_edge_detected)
  );
  
endmodule

//--------------------------------------------
// 重置信号处理单元 - 集成延迟和边沿检测功能
//--------------------------------------------
module reset_signal_processor (
  input  wire clk,
  input  wire reset_n,
  output wire reset_n_delayed,
  output wire reset_edge_detected
);

  // 内部连接信号
  wire internal_delayed_signal;

  // 实例化信号延迟子模块
  delay_register delay_unit (
    .clk        (clk),
    .data_in    (reset_n),
    .data_out   (internal_delayed_signal)
  );

  // 实例化边沿检测子模块
  falling_edge_detector edge_detector_unit (
    .current_signal (reset_n),
    .delayed_signal (internal_delayed_signal),
    .edge_detected  (reset_edge_detected)
  );

  // 输出延迟信号
  assign reset_n_delayed = internal_delayed_signal;
  
endmodule

//--------------------------------------------
// 基本寄存器延迟单元 - 提供可参数化的寄存器延迟
//--------------------------------------------
module delay_register #(
  parameter WIDTH = 1  // 可参数化的数据宽度
) (
  input  wire             clk,
  input  wire [WIDTH-1:0] data_in,
  output reg  [WIDTH-1:0] data_out
);

  // 寄存器延迟逻辑
  always @(posedge clk) begin
    data_out <= data_in;
  end
  
endmodule

//--------------------------------------------
// 下降沿检测器 - 专门用于检测信号的下降沿
//--------------------------------------------
module falling_edge_detector (
  input  wire current_signal,
  input  wire delayed_signal,
  output wire edge_detected
);

  // 当前值为0且前一个值为1时检测到下降沿
  assign edge_detected = ~current_signal & delayed_signal;
  
endmodule