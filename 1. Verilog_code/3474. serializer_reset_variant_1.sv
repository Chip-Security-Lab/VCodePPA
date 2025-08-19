//SystemVerilog
module serializer_reset #(parameter WIDTH = 8)(
  input clk, rst_n, load,
  input [WIDTH-1:0] parallel_in,
  output serial_out
);
  reg [WIDTH-1:0] shift_reg;
  reg [$clog2(WIDTH)-1:0] bit_counter;
  reg [$clog2(WIDTH)-1:0] subtraction_result_reg;
  wire [$clog2(WIDTH)-1:0] subtraction_result;
  
  // 使用并行前缀减法器计算 WIDTH-1-bit_counter
  parallel_prefix_subtractor #(
    .WIDTH($clog2(WIDTH))
  ) subtractor (
    .a(WIDTH-1),                // 常量 WIDTH-1
    .b(bit_counter),            // 被减数
    .result(subtraction_result) // 减法结果
  );
  
  // 将减法结果寄存到下一个时钟周期，实现前向寄存器重定时
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      subtraction_result_reg <= 0;
    end else begin
      subtraction_result_reg <= subtraction_result;
    end
  end
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      shift_reg <= 0;
      bit_counter <= 0;
    end else if (load) begin
      shift_reg <= parallel_in;
      bit_counter <= 0;
    end else if (bit_counter < WIDTH)
      bit_counter <= bit_counter + 1;
  end
  
  // 使用寄存的减法结果读取shift_reg
  assign serial_out = shift_reg[subtraction_result_reg];
endmodule

// 并行前缀减法器实现 - 优化版本
module parallel_prefix_subtractor #(
  parameter WIDTH = 3  // $clog2(8) = 3 bits for 8-bit serializer
)(
  input [WIDTH-1:0] a,        // 被减数
  input [WIDTH-1:0] b,        // 减数
  output [WIDTH-1:0] result   // 结果
);
  wire [WIDTH:0] carry;        // 进位信号
  wire [WIDTH-1:0] b_complement; // 减数的补码
  wire [WIDTH-1:0] p, g;       // 传播和生成信号
  
  // 生成减数的反码
  assign b_complement = ~b;
  
  // 初始进位设为1（补码减法需要）
  assign carry[0] = 1'b1;
  
  // 第一级: 生成基本的传播和生成信号
  genvar i;
  generate
    for (i = 0; i < WIDTH; i = i + 1) begin : gen_pg
      assign p[i] = a[i] ^ b_complement[i];
      assign g[i] = a[i] & b_complement[i];
    end
  endgenerate
  
  // 优化的并行前缀树进位计算，减少关键路径
  generate
    for (i = 0; i < WIDTH; i = i + 1) begin : gen_carry
      assign carry[i+1] = g[i] | (p[i] & carry[i]);
    end
  endgenerate
  
  // 最终减法结果
  generate
    for (i = 0; i < WIDTH; i = i + 1) begin : gen_result
      assign result[i] = p[i] ^ carry[i];
    end
  endgenerate
endmodule