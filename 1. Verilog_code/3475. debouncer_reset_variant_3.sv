//SystemVerilog
// 顶层模块
module debouncer_reset #(
  parameter DELAY = 16
)(
  input  wire clk,
  input  wire rst,
  input  wire button_in,
  output wire button_out
);

  wire [DELAY-1:0] shift_reg;
  wire stable_high;
  wire stable_low;

  // 按钮采样模块实例
  button_sampler #(
    .DELAY(DELAY)
  ) u_button_sampler (
    .clk        (clk),
    .rst        (rst),
    .button_in  (button_in),
    .shift_reg  (shift_reg)
  );

  // 稳定状态检测模块实例
  stability_detector #(
    .DELAY(DELAY)
  ) u_stability_detector (
    .shift_reg   (shift_reg),
    .stable_high (stable_high),
    .stable_low  (stable_low)
  );

  // 输出控制模块实例
  output_controller u_output_controller (
    .clk         (clk),
    .rst         (rst),
    .stable_high (stable_high),
    .stable_low  (stable_low),
    .button_out  (button_out)
  );

endmodule

// 按钮采样模块 - 负责按钮输入采样和位移寄存器管理
module button_sampler #(
  parameter DELAY = 16
)(
  input  wire clk,
  input  wire rst,
  input  wire button_in,
  output reg [DELAY-1:0] shift_reg
);

  always @(posedge clk) begin
    if (rst) begin
      shift_reg <= {DELAY{1'b0}};
    end else begin
      shift_reg <= {shift_reg[DELAY-2:0], button_in};
    end
  end

endmodule

// 稳定状态检测模块 - 负责检测按钮状态是否稳定
module stability_detector #(
  parameter DELAY = 16
)(
  input  wire [DELAY-1:0] shift_reg,
  output wire stable_high,
  output wire stable_low
);

  // 当位移寄存器全为1时表示高电平稳定
  assign stable_high = &shift_reg;
  
  // 当位移寄存器全为0时表示低电平稳定
  assign stable_low = ~|shift_reg;

endmodule

// 输出控制模块 - 根据稳定状态更新输出
module output_controller (
  input  wire clk,
  input  wire rst,
  input  wire stable_high,
  input  wire stable_low,
  output reg  button_out
);

  always @(posedge clk) begin
    if (rst) begin
      button_out <= 1'b0;
    end else begin
      if (stable_high)
        button_out <= 1'b1;
      else if (stable_low)
        button_out <= 1'b0;
    end
  end

endmodule