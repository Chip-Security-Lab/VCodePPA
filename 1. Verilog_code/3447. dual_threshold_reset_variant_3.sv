//SystemVerilog
// 顶层模块
module dual_threshold_reset #(
  parameter LEVEL_WIDTH = 8
)(
  input  wire                    clk,
  input  wire                    rst_n,  // 外部异步复位输入
  input  wire [LEVEL_WIDTH-1:0]  level,
  input  wire [LEVEL_WIDTH-1:0]  upper_threshold,
  input  wire [LEVEL_WIDTH-1:0]  lower_threshold,
  output wire                    reset_out
);
  
  // 内部连线
  wire threshold_compare_upper;
  wire threshold_compare_lower;
  
  // 实例化阈值比较器子模块
  threshold_detector #(
    .DATA_WIDTH(LEVEL_WIDTH)
  ) threshold_comp (
    .level(level),
    .upper_threshold(upper_threshold),
    .lower_threshold(lower_threshold),
    .above_upper(threshold_compare_upper),
    .below_lower(threshold_compare_lower)
  );
  
  // 实例化状态控制器子模块
  hysteresis_controller reset_ctrl (
    .clk(clk),
    .rst_n(rst_n),
    .above_upper(threshold_compare_upper),
    .below_lower(threshold_compare_lower),
    .reset_out(reset_out)
  );
  
endmodule

// 阈值检测器子模块 - 负责比较输入电平与阈值
module threshold_detector #(
  parameter DATA_WIDTH = 8
)(
  input  wire [DATA_WIDTH-1:0] level,
  input  wire [DATA_WIDTH-1:0] upper_threshold,
  input  wire [DATA_WIDTH-1:0] lower_threshold,
  output wire                  above_upper,
  output wire                  below_lower
);
  
  // 优化比较逻辑，使用寄存器减少组合路径
  reg [DATA_WIDTH-1:0] level_reg;
  reg [DATA_WIDTH-1:0] upper_threshold_reg;
  reg [DATA_WIDTH-1:0] lower_threshold_reg;
  
  always @(*) begin
    level_reg = level;
    upper_threshold_reg = upper_threshold;
    lower_threshold_reg = lower_threshold;
  end
  
  // 使用参数化宽度进行比较
  assign above_upper = (level_reg > upper_threshold_reg);
  assign below_lower = (level_reg < lower_threshold_reg);
  
endmodule

// 磁滞控制器子模块 - 实现状态切换逻辑
module hysteresis_controller (
  input  wire clk,
  input  wire rst_n,        // 添加异步复位
  input  wire above_upper,
  input  wire below_lower,
  output reg  reset_out
);
  
  // 状态定义
  localparam STATE_NORMAL  = 1'b0;
  localparam STATE_RESET   = 1'b1;
  
  reg state_current, state_next;
  
  // 状态寄存器
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      state_current <= STATE_NORMAL;
    else
      state_current <= state_next;
  end
  
  // 下一状态逻辑
  always @(*) begin
    state_next = state_current;  // 默认保持当前状态
    
    case (state_current)
      STATE_NORMAL: if (above_upper) state_next = STATE_RESET;
      STATE_RESET:  if (below_lower) state_next = STATE_NORMAL;
    endcase
  end
  
  // 输出逻辑
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      reset_out <= 1'b0;
    else
      reset_out <= (state_next == STATE_RESET);
  end
  
endmodule