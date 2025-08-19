//SystemVerilog
module param_register_reset #(
  parameter WIDTH = 16,
  parameter RESET_VALUE = 16'hFFFF,
  parameter PIPELINE_STAGES = 3  // 定义流水线级数
)(
  input clk, rst_n, load,
  input [WIDTH-1:0] data_in,
  output [WIDTH-1:0] data_out
);
  // 流水线寄存器 - 前向寄存器重定时优化
  reg [WIDTH-1:0] stage1_data, stage2_data, stage3_data;
  reg stage1_valid, stage2_valid, stage3_valid;
  
  // 直接将输入传递到组合逻辑节点
  wire [WIDTH-1:0] processed_data;
  wire processed_valid;
  
  // 数据预处理组合逻辑
  assign processed_data = data_in;
  assign processed_valid = load;
  
  // 重定时后的第一级流水线 - 将寄存器移动到组合逻辑之后
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      stage1_data <= RESET_VALUE;
      stage1_valid <= 1'b0;
    end else begin
      stage1_data <= processed_data;
      stage1_valid <= processed_valid;
    end
  end
  
  // 第二级流水线
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      stage2_data <= RESET_VALUE;
      stage2_valid <= 1'b0;
    end else begin
      stage2_data <= stage1_data;
      stage2_valid <= stage1_valid;
    end
  end
  
  // 第三级流水线
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      stage3_data <= RESET_VALUE;
      stage3_valid <= 1'b0;
    end else begin
      stage3_data <= stage2_data;
      stage3_valid <= stage2_valid;
    end
  end
  
  // 输出赋值
  assign data_out = stage3_data;
  
endmodule