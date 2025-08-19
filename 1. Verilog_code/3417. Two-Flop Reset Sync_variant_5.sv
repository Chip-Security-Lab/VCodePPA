//SystemVerilog
//IEEE 1364-2005 Verilog标准
module RD7(
  input clk,
  input rst_n_in,
  output rst_n_out
);

  // 内部信号连接
  wire reset_detect_signal;
  
  // 实例化复位检测子模块
  reset_detector reset_detector_inst(
    .clk(clk),
    .rst_n_in(rst_n_in),
    .reset_detected(reset_detect_signal)
  );
  
  // 实例化复位处理子模块
  reset_controller reset_controller_inst(
    .clk(clk),
    .reset_detected(reset_detect_signal),
    .rst_n_out(rst_n_out)
  );

endmodule

// 复位检测子模块
module reset_detector(
  input clk,
  input rst_n_in,
  output reg reset_detected
);

  always @(posedge clk or negedge rst_n_in) begin
    if (!rst_n_in) begin
      reset_detected <= 1'b1; // 检测到复位
    end else begin
      reset_detected <= 1'b0; // 无复位
    end
  end

endmodule

// 复位控制子模块
module reset_controller(
  input clk,
  input reset_detected,
  output reg rst_n_out
);

  always @(posedge clk) begin
    if (reset_detected) begin
      rst_n_out <= 1'b0; // 激活复位
    end else begin
      rst_n_out <= 1'b1; // 释放复位
    end
  end

endmodule