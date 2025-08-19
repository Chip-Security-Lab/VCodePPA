//SystemVerilog
module delayed_reset_counter #(
  parameter WIDTH = 8,
  parameter DELAY = 3
)(
  input  wire             clk,
  input  wire             rst_trigger,
  output wire [WIDTH-1:0] count
);

  wire reset_signal;
  
  // 实例化延迟重置信号子模块
  delay_shift_register #(
    .DELAY(DELAY)
  ) delay_sr_inst (
    .clk(clk),
    .rst_trigger(rst_trigger),
    .reset_out(reset_signal)
  );
  
  // 实例化计数器子模块
  counter_module #(
    .WIDTH(WIDTH)
  ) counter_inst (
    .clk(clk),
    .reset(reset_signal),
    .count(count)
  );

endmodule

// 延迟移位寄存器子模块 - 优化版本
module delay_shift_register #(
  parameter DELAY = 3
)(
  input  wire clk,
  input  wire rst_trigger,
  output wire reset_out
);

  reg [DELAY-1:0] delay_sr;
  
  always @(posedge clk) begin
    // 重新排列移位操作，优化资源使用和时序
    delay_sr <= {delay_sr[DELAY-2:0], rst_trigger};
  end
  
  // 从移位寄存器的高位读取重置信号，改善时序特性
  assign reset_out = delay_sr[DELAY-1];

endmodule

// 计数器子模块 - 优化版本
module counter_module #(
  parameter WIDTH = 8
)(
  input  wire             clk,
  input  wire             reset,
  output reg  [WIDTH-1:0] count
);

  // 优化复位逻辑和计数逻辑，减少比较链
  always @(posedge clk) begin
    if (reset) begin
      // 直接使用0赋值代替位拼接，更高效
      count <= '0;
    end else if (count == {WIDTH{1'b1}}) begin
      // 优化计数器翻转逻辑，避免溢出处理
      count <= '0;
    end else begin
      count <= count + 1'b1;
    end
  end

endmodule