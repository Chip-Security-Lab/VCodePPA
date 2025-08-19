//SystemVerilog
module adaptive_reset_threshold (
  input  wire        clk,
  input  wire [7:0]  signal_level,
  input  wire [7:0]  base_threshold,
  input  wire [3:0]  hysteresis,
  output reg         reset_trigger
);

  // 状态定义
  localparam STATE_INACTIVE = 1'b0;
  localparam STATE_ACTIVE   = 1'b1;

  // 流水线级寄存器
  reg [7:0] signal_level_r1;
  reg [7:0] base_threshold_r1;
  reg [3:0] hysteresis_r1;
  reg [7:0] current_threshold;

  // 第一级流水线：输入信号寄存
  always @(posedge clk) begin
    signal_level_r1    <= signal_level;
    base_threshold_r1  <= base_threshold;
    hysteresis_r1      <= hysteresis;
  end

  // 阈值比较逻辑
  wire signal_below_threshold;
  reg  signal_compare_result;

  assign signal_below_threshold = (signal_level_r1 < current_threshold);
  
  // 第二级流水线：比较结果寄存
  always @(posedge clk) begin
    signal_compare_result <= signal_below_threshold;
  end

  // 状态转换控制路径
  reg  current_state;
  wire [1:0] condition_vector;
  reg  next_state;
  reg  [7:0] next_threshold;

  // 条件向量构建
  assign condition_vector = {current_state, signal_compare_result};

  // 第三级流水线：状态存储
  always @(posedge clk) begin
    current_state <= reset_trigger;
  end

  // 状态转换和阈值调整逻辑
  always @(*) begin
    case (condition_vector)
      // [非激活状态, 信号低于阈值] => 激活复位
      2'b01: begin
        next_state = STATE_ACTIVE;
        next_threshold = base_threshold_r1 + hysteresis_r1;
      end
      
      // [激活状态, 信号高于阈值] => 取消复位
      2'b10: begin
        next_state = STATE_INACTIVE;
        next_threshold = base_threshold_r1;
      end
      
      // 保持当前状态
      default: begin
        next_state = current_state;
        next_threshold = current_threshold;
      end
    endcase
  end
  
  // 第四级流水线：输出和阈值更新
  always @(posedge clk) begin
    reset_trigger <= next_state;
    current_threshold <= next_threshold;
  end

endmodule