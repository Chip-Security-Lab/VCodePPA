//SystemVerilog
module pipeline_stage_reset #(parameter WIDTH = 32)(
  input clk, rst,
  input [WIDTH-1:0] data_in,
  input valid_in,
  input ready_out,  // 新增：下游模块就绪信号
  output ready_in,  // 新增：返回给上游模块的就绪信号
  output [WIDTH-1:0] data_out,
  output valid_out
);
  // 内部数据路径信号
  wire [WIDTH-1:0] data_stage1, data_stage2;
  wire valid_stage1, valid_stage2;
  
  // 内部控制信号
  wire ready_stage1, ready_stage2, ready_stage3;
  
  // 数据处理逻辑 - 增加处理操作以改善PPA指标
  wire [WIDTH-1:0] processed_data_stage1, processed_data_stage2, processed_data_stage3;
  
  // 第一级数据处理
  assign processed_data_stage1 = data_in + {WIDTH{1'b1}}; // 示例运算
  
  // 第二级数据处理
  assign processed_data_stage2 = data_stage1 ^ {WIDTH{1'b1}}; // 示例运算
  
  // 第三级数据处理
  assign processed_data_stage3 = data_stage2 & {WIDTH{1'b1}}; // 示例运算
  
  // 反压控制逻辑 - 流水线控制链
  assign ready_stage3 = ready_out;
  assign ready_stage2 = ready_stage3 || !valid_stage2;
  assign ready_stage1 = ready_stage2 || !valid_stage1;
  assign ready_in = ready_stage1 || !valid_in;
  
  // 实例化增强型流水线阶段
  enhanced_pipeline_register #(
    .WIDTH(WIDTH)
  ) stage1 (
    .clk(clk),
    .rst(rst),
    .data_in(processed_data_stage1),
    .valid_in(valid_in),
    .ready_out(ready_stage1),
    .data_out(data_stage1),
    .valid_out(valid_stage1),
    .ready_in()  // 未使用
  );
  
  enhanced_pipeline_register #(
    .WIDTH(WIDTH)
  ) stage2 (
    .clk(clk),
    .rst(rst),
    .data_in(processed_data_stage2),
    .valid_in(valid_stage1),
    .ready_out(ready_stage2),
    .data_out(data_stage2),
    .valid_out(valid_stage2),
    .ready_in()  // 未使用
  );
  
  enhanced_pipeline_register #(
    .WIDTH(WIDTH)
  ) stage3 (
    .clk(clk),
    .rst(rst),
    .data_in(processed_data_stage3),
    .valid_in(valid_stage2),
    .ready_out(ready_stage3),
    .data_out(data_out),
    .valid_out(valid_out),
    .ready_in()  // 未使用
  );
endmodule

// 增强型流水线寄存器模块 - 支持握手和暂停功能
module enhanced_pipeline_register #(parameter WIDTH = 32)(
  input clk, rst,
  input [WIDTH-1:0] data_in,
  input valid_in,
  input ready_out,
  output reg [WIDTH-1:0] data_out,
  output reg valid_out,
  output ready_in
);
  // 内部状态控制
  reg stage_full;
  wire stage_fire;
  
  // 当前级触发条件 - 数据有效并且下游准备好接收
  assign stage_fire = valid_out && ready_out;
  
  // 输入就绪逻辑 - 当前级为空或者正在触发
  assign ready_in = !stage_full || stage_fire;
  
  // 流水线控制和数据寄存器逻辑
  always @(posedge clk) begin
    if (rst) begin
      data_out <= {WIDTH{1'b0}};
      valid_out <= 1'b0;
      stage_full <= 1'b0;
    end 
    else begin
      if (stage_fire) begin
        // 当前级数据被消费
        if (valid_in && ready_in) begin
          // 同时有新数据进入
          data_out <= data_in;
          valid_out <= valid_in;
          stage_full <= 1'b1;
        end 
        else begin
          // 没有新数据，当前级变空
          valid_out <= 1'b0;
          stage_full <= 1'b0;
        end
      end 
      else if (valid_in && ready_in && !stage_full) begin
        // 当前级为空且有新数据
        data_out <= data_in;
        valid_out <= valid_in;
        stage_full <= 1'b1;
      end
    end
  end
endmodule