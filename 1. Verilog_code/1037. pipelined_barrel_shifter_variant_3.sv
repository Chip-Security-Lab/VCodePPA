//SystemVerilog
module pipelined_barrel_shifter (
  input         clk,
  input         rst,
  input  [31:0] data_in,
  input  [4:0]  shift,
  output reg [31:0] data_out
);

  // 前向寄存器重定时后的流水线结构

  // 第一阶段组合逻辑
  wire [31:0] stage1_comb;
  assign stage1_comb = shift[4] ? {data_in[15:0], 16'b0} : data_in;

  // 第二阶段组合逻辑
  wire [31:0] stage2_comb;
  assign stage2_comb = shift[3] ? {stage1_comb[23:0], 8'b0} : stage1_comb;

  // 第三阶段组合逻辑
  wire [31:0] stage3_comb;
  assign stage3_comb = shift[2:0] ? (stage2_comb << shift[2:0]) : stage2_comb;

  // 第一阶段寄存器，移到所有组合逻辑之后
  reg [31:0] reg_stage3;
  always @(posedge clk or posedge rst) begin
    if (rst)
      reg_stage3 <= 32'b0;
    else
      reg_stage3 <= stage3_comb;
  end

  // 输出寄存器
  always @(posedge clk or posedge rst) begin
    if (rst)
      data_out <= 32'b0;
    else
      data_out <= reg_stage3;
  end

endmodule