//SystemVerilog (IEEE 1364-2005)
module lfsr_with_reset #(
  parameter WIDTH = 8
)(
  input wire clk,
  input wire async_rst,
  input wire enable,
  output wire [WIDTH-1:0] lfsr_out
);
  
  // 内部寄存器
  reg [WIDTH-1:0] lfsr_reg;
  
  // 将组合逻辑分离到独立模块
  lfsr_comb_logic #(
    .WIDTH(WIDTH)
  ) comb_logic_inst (
    .current_state(lfsr_reg),
    .enable(enable),
    .next_state(lfsr_out)
  );
  
  // 时序逻辑保持在主模块中
  always @(posedge clk or posedge async_rst) begin
    if (async_rst) begin
      lfsr_reg <= {{(WIDTH-1){1'b0}}, 1'b1};  // 参数化的非零种子值
    end else begin
      lfsr_reg <= lfsr_out;
    end
  end

endmodule

//SystemVerilog (IEEE 1364-2005)
module lfsr_comb_logic #(
  parameter WIDTH = 8
)(
  input wire [WIDTH-1:0] current_state,
  input wire enable,
  output wire [WIDTH-1:0] next_state
);
  
  // 反馈逻辑信号声明
  wire feedback;
  wire [3:0] feedback_terms;
  
  // 使用assign语句替代always块，改善组合逻辑结构
  assign feedback_terms[0] = current_state[WIDTH-1];
  assign feedback_terms[1] = (WIDTH == 8) ? current_state[5] : current_state[WIDTH-5];
  assign feedback_terms[2] = (WIDTH == 8) ? current_state[4] : current_state[WIDTH-6];
  assign feedback_terms[3] = (WIDTH == 8) ? current_state[3] : current_state[WIDTH-7];
  
  // 优化异或树结构以降低延迟
  wire feedback_part1, feedback_part2;
  assign feedback_part1 = feedback_terms[0] ^ feedback_terms[1];
  assign feedback_part2 = feedback_terms[2] ^ feedback_terms[3];
  assign feedback = feedback_part1 ^ feedback_part2;
  
  // 使用条件运算符简化enable逻辑
  assign next_state = enable ? {current_state[WIDTH-2:0], feedback} : current_state;

endmodule