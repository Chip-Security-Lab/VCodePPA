//SystemVerilog
// 顶层模块
module debounce_reset_monitor #(
  parameter DEBOUNCE_CYCLES = 8
) (
  input  wire clk,
  input  wire reset_in,
  output wire reset_out
);
  // 内部信号
  wire reset_changed;
  wire counter_full;
  wire [1:0] control_state;
  wire [$clog2(DEBOUNCE_CYCLES)-1:0] counter_value;
  wire reset_in_sync;
  
  // 同步器子模块实例
  reset_synchronizer reset_sync_inst (
    .clk        (clk),
    .reset_in   (reset_in),
    .reset_sync (reset_in_sync)
  );
  
  // 状态检测子模块实例
  state_detector state_det_inst (
    .reset_in_sync  (reset_in_sync),
    .reset_in       (reset_in),
    .counter_value  (counter_value),
    .debounce_max   (DEBOUNCE_CYCLES-1),
    .reset_changed  (reset_changed),
    .counter_full   (counter_full),
    .control_state  (control_state)
  );
  
  // 计数器控制子模块实例
  counter_controller counter_ctrl_inst (
    .clk            (clk),
    .control_state  (control_state),
    .counter_value  (counter_value)
  );
  
  // 输出控制子模块实例
  output_controller output_ctrl_inst (
    .clk            (clk),
    .control_state  (control_state),
    .reset_in_sync  (reset_in_sync),
    .reset_out      (reset_out)
  );
  
endmodule

// 同步器子模块
module reset_synchronizer (
  input  wire clk,
  input  wire reset_in,
  output reg  reset_sync
);
  always @(posedge clk) begin
    reset_sync <= reset_in;
  end
endmodule

// 状态检测子模块
module state_detector #(
  parameter MAX_COUNT_WIDTH = 8
) (
  input  wire reset_in_sync,
  input  wire reset_in,
  input  wire [MAX_COUNT_WIDTH-1:0] counter_value,
  input  wire [MAX_COUNT_WIDTH-1:0] debounce_max,
  output wire reset_changed,
  output wire counter_full,
  output wire [1:0] control_state
);
  // 检测复位信号变化
  assign reset_changed = (reset_in_sync != reset_in);
  
  // 检测计数器是否达到最大值
  assign counter_full = (counter_value >= debounce_max);
  
  // 生成控制状态
  assign control_state = {reset_changed, counter_full};
endmodule

// 计数器控制子模块
module counter_controller #(
  parameter DEBOUNCE_CYCLES = 8
) (
  input  wire clk,
  input  wire [1:0] control_state,
  output reg  [$clog2(DEBOUNCE_CYCLES)-1:0] counter_value
);
  // 计数器逻辑
  always @(posedge clk) begin
    case(control_state)
      2'b10,  // 复位信号改变
      2'b11:  // 复位信号改变且计数器已满（合并相同处理情况）
        counter_value <= 0;
        
      2'b00:  // 复位信号未改变且计数器未满
        counter_value <= counter_value + 1;
        
      2'b01:  // 复位信号未改变且计数器已满
        counter_value <= counter_value; // 保持当前值
    endcase
  end
endmodule

// 输出控制子模块
module output_controller (
  input  wire clk,
  input  wire [1:0] control_state,
  input  wire reset_in_sync,
  output reg  reset_out
);
  // 输出控制逻辑
  always @(posedge clk) begin
    if (control_state == 2'b01) begin
      // 仅在复位信号稳定且计数器已满时更新输出
      reset_out <= reset_in_sync;
    end
  end
endmodule