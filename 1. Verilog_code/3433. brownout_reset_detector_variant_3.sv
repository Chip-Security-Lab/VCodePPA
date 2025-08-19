//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

// 顶层模块：棕色复出检测器
module brownout_reset_detector #(
  parameter THRESHOLD = 8'h80
) (
  input  wire clk,
  input  wire [7:0] voltage_level,
  output wire brownout_reset
);
  // 内部连线
  wire voltage_below_threshold;
  wire voltage_below_threshold_reg;
  wire [1:0] voltage_state;

  // 电压比较子模块实例化
  voltage_comparator #(
    .THRESHOLD(THRESHOLD)
  ) comparator_inst (
    .clk(clk),
    .voltage_level(voltage_level),
    .below_threshold(voltage_below_threshold),
    .below_threshold_reg(voltage_below_threshold_reg)
  );

  // 状态跟踪子模块实例化
  state_tracker state_tracker_inst (
    .clk(clk),
    .below_threshold(voltage_below_threshold_reg),
    .voltage_state(voltage_state)
  );

  // 复位生成子模块实例化
  reset_generator reset_gen_inst (
    .clk(clk),
    .voltage_state(voltage_state),
    .brownout_reset(brownout_reset)
  );

endmodule

// 子模块1：电压比较器
module voltage_comparator #(
  parameter THRESHOLD = 8'h80
) (
  input  wire clk,
  input  wire [7:0] voltage_level,
  output wire below_threshold,
  output reg below_threshold_reg
);
  
  // 组合逻辑先计算结果
  assign below_threshold = (voltage_level < THRESHOLD);
  
  // 寄存器捕获组合逻辑结果
  always @(posedge clk) begin
    below_threshold_reg <= below_threshold;
  end
  
endmodule

// 子模块2：状态跟踪器
module state_tracker (
  input  wire clk,
  input  wire below_threshold,
  output reg [1:0] voltage_state
);
  
  // 寄存器移动前的组合逻辑
  wire [1:0] next_state;
  assign next_state = {voltage_state[0], below_threshold};
  
  always @(posedge clk) begin
    voltage_state <= next_state;
  end
  
endmodule

// 子模块3：复位信号生成器
module reset_generator (
  input  wire clk,
  input  wire [1:0] voltage_state,
  output wire brownout_reset
);
  
  // 组合逻辑计算重置信号
  wire reset_comb;
  reg reset_reg;
  
  assign reset_comb = &voltage_state;
  assign brownout_reset = reset_reg;
  
  always @(posedge clk) begin
    reset_reg <= reset_comb;
  end
  
endmodule