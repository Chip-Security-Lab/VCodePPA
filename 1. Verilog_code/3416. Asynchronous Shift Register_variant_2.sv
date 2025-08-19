//SystemVerilog
// 顶层模块，实例化并连接子模块
module RD6 #(parameter WIDTH=8, DEPTH=4)(
  input clk, 
  input arstn,
  input [WIDTH-1:0] shift_in,
  output [WIDTH-1:0] shift_out
);
  // 内部连线
  wire [WIDTH-1:0] sub_result;
  wire sub_control;
  wire [WIDTH:0] extended_result;
  
  // 条件反相减法器模块实例化
  ConditionalSubtractor #(
    .WIDTH(WIDTH)
  ) u_subtractor (
    .operand_a(shift_in),
    .operand_b(shift_in), // 第一级寄存器的输入
    .sub_result(sub_result),
    .sub_control(sub_control)
  );
  
  // 拓展结果生成
  assign extended_result = {sub_control, sub_result};
  
  // 移位寄存器模块实例化
  ShiftRegister #(
    .WIDTH(WIDTH),
    .DEPTH(DEPTH)
  ) u_shift_register (
    .clk(clk),
    .arstn(arstn),
    .shift_in(shift_in),
    .shift_out(shift_out)
  );
  
endmodule

// 条件反相减法器模块 - 根据输入大小关系执行不同的减法操作
module ConditionalSubtractor #(parameter WIDTH=8)(
  input [WIDTH-1:0] operand_a,
  input [WIDTH-1:0] operand_b,
  output reg [WIDTH-1:0] sub_result,
  output reg sub_control
);
  
  // 条件反相减法器算法
  always @(*) begin
    sub_control = operand_a < operand_b;
    
    if (sub_control) begin
      // 当A<B时，计算B-A并反相结果
      sub_result = operand_b - operand_a;
      sub_result = ~sub_result + 1'b1;
    end else begin
      // 当A>=B时，直接计算A-B
      sub_result = operand_a - operand_b;
    end
  end
  
endmodule

// 移位寄存器模块 - 管理多级寄存器链
module ShiftRegister #(parameter WIDTH=8, DEPTH=4)(
  input clk,
  input arstn,
  input [WIDTH-1:0] shift_in,
  output [WIDTH-1:0] shift_out
);
  
  reg [WIDTH-1:0] shreg [0:DEPTH-1];
  integer j;
  
  // 移位寄存器逻辑
  always @(posedge clk or negedge arstn) begin
    if (!arstn) begin
      for (j=0; j<DEPTH; j=j+1)
        shreg[j] <= {WIDTH{1'b0}};
    end else begin
      // 第一级寄存器接收输入
      shreg[0] <= shift_in;
      
      // 后续级联寄存器进行移位
      for (j=1; j<DEPTH; j=j+1)
        shreg[j] <= shreg[j-1];
    end
  end
  
  assign shift_out = shreg[DEPTH-1];
  
endmodule