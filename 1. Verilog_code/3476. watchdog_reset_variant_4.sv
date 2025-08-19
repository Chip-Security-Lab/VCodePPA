//SystemVerilog
module watchdog_reset #(parameter TIMEOUT = 1000)(
  input clk, ext_rst_n, watchdog_clear,
  output reg watchdog_rst
);
  wire [$clog2(TIMEOUT)-1:0] timer;
  reg [$clog2(TIMEOUT)-1:0] timer_reg;
  wire [$clog2(TIMEOUT)-1:0] next_timer;
  wire timeout_reached;
  reg watchdog_clear_reg;
  
  // 将输入寄存器化，减少输入到第一级寄存器的路径
  always @(posedge clk or negedge ext_rst_n) begin
    if (!ext_rst_n) begin
      watchdog_clear_reg <= 0;
    end else begin
      watchdog_clear_reg <= watchdog_clear;
    end
  end
  
  // Parallel prefix subtractor implementation
  parallel_prefix_subtractor #(
    .WIDTH($clog2(TIMEOUT))
  ) subtractor (
    .a(TIMEOUT - 1),
    .b(timer),
    .diff(/* unused */),
    .comparison_result(timeout_reached)
  );
  
  // Increment timer using adder
  adder #(
    .WIDTH($clog2(TIMEOUT))
  ) timer_adder (
    .a(timer),
    .b({{($clog2(TIMEOUT)-1){1'b0}}, 1'b1}),
    .sum(next_timer)
  );
  
  // 记录当前timer值用于组合逻辑计算
  assign timer = timer_reg;
  
  // 重定时主状态寄存器 - 移动到组合逻辑之后
  always @(posedge clk or negedge ext_rst_n) begin
    if (!ext_rst_n) begin
      timer_reg <= 0;
      watchdog_rst <= 0;
    end else if (watchdog_clear_reg) begin
      timer_reg <= 0;
      watchdog_rst <= 0;
    end else if (!timeout_reached) begin
      timer_reg <= next_timer;
    end else begin
      watchdog_rst <= 1;
    end
  end
endmodule

// Optimized parallel prefix adder
module adder #(parameter WIDTH = 8)(
  input [WIDTH-1:0] a,
  input [WIDTH-1:0] b,
  output [WIDTH-1:0] sum
);
  wire [WIDTH-1:0] p, g;
  wire [WIDTH-1:0] carry;
  
  // Generate propagate and generate signals
  assign p = a ^ b;
  assign g = a & b;
  
  // 优化前缀计算
  wire [WIDTH:0] c;
  assign c[0] = 1'b0;
  
  genvar i;
  generate
    for (i = 0; i < WIDTH; i = i + 1) begin: carry_chain
      assign c[i+1] = g[i] | (p[i] & c[i]);
    end
  endgenerate
  
  // Compute carries
  assign carry = c[WIDTH:1];
  
  // Compute sum
  assign sum = p ^ carry;
endmodule

// Optimized parallel prefix subtractor with comparison
module parallel_prefix_subtractor #(parameter WIDTH = 8)(
  input [WIDTH-1:0] a,
  input [WIDTH-1:0] b,
  output [WIDTH-1:0] diff,
  output comparison_result
);
  wire [WIDTH-1:0] not_b;
  wire [WIDTH-1:0] p, g;
  wire [WIDTH-1:0] carry;
  
  // One's complement of b
  assign not_b = ~b;
  
  // Generate propagate and generate signals for a - b = a + (~b) + 1
  assign p = a ^ not_b;
  assign g = a & not_b;
  
  // 优化前缀计算过程 - 使用简化的进位链
  wire [WIDTH:0] c;
  assign c[0] = 1'b1; // 减法初始进位为1
  
  genvar i;
  generate
    for (i = 0; i < WIDTH; i = i + 1) begin: carry_chain
      assign c[i+1] = g[i] | (p[i] & c[i]);
    end
  endgenerate
  
  // Compute carries
  assign carry = c[WIDTH:1];
  
  // Compute difference
  assign diff = p ^ c[WIDTH:1];
  
  // Comparison result: a >= b if MSB carry is set (no borrow)
  assign comparison_result = carry[WIDTH-1];
endmodule