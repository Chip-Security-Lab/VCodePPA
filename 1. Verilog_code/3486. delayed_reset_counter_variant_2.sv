//SystemVerilog
module delayed_reset_counter #(
  parameter WIDTH = 8,
  parameter DELAY = 3
)(
  input  wire clk,
  input  wire rst_trigger,
  output wire [WIDTH-1:0] count
);
  
  wire delayed_reset;
  
  // 实例化延迟重置子模块
  reset_delay_generator #(
    .DELAY(DELAY)
  ) reset_delay_inst (
    .clk(clk),
    .rst_trigger(rst_trigger),
    .delayed_reset(delayed_reset)
  );
  
  // 实例化计数器子模块
  counter_module #(
    .WIDTH(WIDTH)
  ) counter_inst (
    .clk(clk),
    .reset(delayed_reset),
    .count(count)
  );
  
endmodule

module reset_delay_generator #(
  parameter DELAY = 3
)(
  input  wire clk,
  input  wire rst_trigger,
  output wire delayed_reset
);
  
  reg [DELAY-1:0] delay_shift;
  
  assign delayed_reset = delay_shift[0];
  
  always @(posedge clk) begin
    delay_shift <= {rst_trigger, delay_shift[DELAY-1:1]};
  end
  
endmodule

module counter_module #(
  parameter WIDTH = 8
)(
  input  wire clk,
  input  wire reset,
  output reg [WIDTH-1:0] count
);
  
  reg [WIDTH-1:0] minuend;      // 被减数
  reg [WIDTH-1:0] subtrahend;   // 减数
  reg subtract_op;              // 减法操作标志
  reg [WIDTH-1:0] next_count;   // 下一状态计数值
  
  // 条件反相减法器实现
  always @(*) begin
    if (reset) begin
      next_count = {WIDTH{1'b0}};
    end else begin
      subtract_op = 1'b0;       // 默认为加法操作
      minuend = count;          // 被减数为当前计数值
      subtrahend = {WIDTH{1'b1}}; // 减数设为全1（等效于-1的补码）
      
      // 条件反相减法实现
      if (subtract_op) begin
        // 减法: 对减数取反加1 (二进制补码)
        next_count = minuend + (~subtrahend + 1'b1);
      end else begin
        // 加法: 直接相加
        next_count = minuend + subtrahend + 1'b1; // +1相当于count+1
      end
    end
  end
  
  always @(posedge clk) begin
    if (reset)
      count <= {WIDTH{1'b0}};
    else
      count <= next_count;
  end
  
endmodule