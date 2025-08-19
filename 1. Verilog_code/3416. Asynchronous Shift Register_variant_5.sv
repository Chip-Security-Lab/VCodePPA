//SystemVerilog
// 顶层模块
module RD6 #(
  parameter WIDTH = 8,
  parameter DEPTH = 4
)(
  input  wire              clk,
  input  wire              arstn,
  input  wire [WIDTH-1:0]  shift_in,
  output wire [WIDTH-1:0]  shift_out
);
  
  // 内部连线，用于连接各级移位寄存器
  // 增加了流水线级数，每个原始级别拆分为2个子级
  wire [WIDTH-1:0] stage_connections [0:(DEPTH*2)-1];
  
  // 将输入连接到第一级
  assign stage_connections[0] = shift_in;
  
  // 实例化各个移位寄存器级
  // 每个原始级别现在被拆分为两个子级别以减轻每级负载
  genvar i;
  generate
    for (i = 0; i < (DEPTH*2)-1; i = i + 1) begin : shift_stages
      EnhancedShiftRegisterStage #(
        .WIDTH(WIDTH)
      ) stage (
        .clk       (clk),
        .arstn     (arstn),
        .data_in   (stage_connections[i]),
        .data_out  (stage_connections[i+1])
      );
    end
  endgenerate
  
  // 最后一级连接到输出
  EnhancedShiftRegisterStage #(
    .WIDTH(WIDTH)
  ) final_stage (
    .clk       (clk),
    .arstn     (arstn),
    .data_in   (stage_connections[(DEPTH*2)-2]),
    .data_out  (shift_out)
  );
  
endmodule

// 增强型移位寄存器子模块，拆分计算负载以提高频率
module EnhancedShiftRegisterStage #(
  parameter WIDTH = 8
)(
  input  wire              clk,
  input  wire              arstn,
  input  wire [WIDTH-1:0]  data_in,
  output reg  [WIDTH-1:0]  data_out
);

  // 增加中间寄存器以平衡各级计算负载
  reg [WIDTH-1:0] data_intermediate;
  
  // 第一阶段 - 数据捕获
  always @(posedge clk or negedge arstn) begin
    if (!arstn) begin
      data_intermediate <= {WIDTH{1'b0}};
    end else begin
      data_intermediate <= data_in;
    end
  end
  
  // 第二阶段 - 数据输出
  always @(posedge clk or negedge arstn) begin
    if (!arstn) begin
      data_out <= {WIDTH{1'b0}};
    end else begin
      data_out <= data_intermediate;
    end
  end
  
endmodule