//SystemVerilog
module bidirectional_counter_reset #(parameter WIDTH = 8)(
  input clk, reset, up_down, load, enable,
  input [WIDTH-1:0] data_in,
  output [WIDTH-1:0] count
);
  // 内部连线
  wire [2:0] ctrl_signals;
  wire [WIDTH-1:0] next_count;

  // 实例化控制逻辑模块
  counter_control_unit control_unit (
    .reset(reset),
    .load(load),
    .enable(enable),
    .ctrl_signals(ctrl_signals)
  );
  
  // 实例化计数器更新逻辑模块
  counter_update_logic #(.WIDTH(WIDTH)) update_logic (
    .ctrl_signals(ctrl_signals),
    .up_down(up_down),
    .data_in(data_in),
    .current_count(count),
    .next_count(next_count)
  );
  
  // 实例化寄存器模块
  counter_register #(.WIDTH(WIDTH)) count_reg (
    .clk(clk),
    .next_count(next_count),
    .count(count)
  );
endmodule

// 控制单元 - 生成控制信号
module counter_control_unit (
  input reset, load, enable,
  output reg [2:0] ctrl_signals
);
  always @(*) begin
    // 组合控制信号: {reset, load, enable}
    ctrl_signals = {reset, load, enable & ~load & ~reset};
  end
endmodule

// 计数器更新逻辑 - 根据控制信号计算下一个计数值
module counter_update_logic #(parameter WIDTH = 8)(
  input [2:0] ctrl_signals,
  input up_down,
  input [WIDTH-1:0] data_in,
  input [WIDTH-1:0] current_count,
  output reg [WIDTH-1:0] next_count
);
  always @(*) begin
    case (ctrl_signals)
      3'b100: next_count = {WIDTH{1'b0}};         // reset优先
      3'b010: next_count = data_in;               // load次优先
      3'b001: next_count = up_down ? current_count + 1'b1 : current_count - 1'b1; // enable情况
      default: next_count = current_count;        // 保持当前值
    endcase
  end
endmodule

// 计数器寄存器 - 存储当前计数值
module counter_register #(parameter WIDTH = 8)(
  input clk,
  input [WIDTH-1:0] next_count,
  output reg [WIDTH-1:0] count
);
  always @(posedge clk) begin
    count <= next_count;
  end
endmodule