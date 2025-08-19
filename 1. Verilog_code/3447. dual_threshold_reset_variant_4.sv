//SystemVerilog
// 顶层模块
module dual_threshold_reset (
  input wire clk,
  input wire rst_n, // 添加复位信号
  input wire [7:0] level,
  input wire [7:0] upper_threshold,
  input wire [7:0] lower_threshold,
  input wire valid_in, // 输入有效信号
  output wire valid_out, // 输出有效信号
  output wire reset_out
);
  // 流水线阶段信号声明
  wire threshold_exceeded_stage1;
  wire threshold_cleared_stage1;
  reg valid_stage1, valid_stage2;
  
  // 阶段1: 阈值比较
  threshold_comparator_pipelined u_threshold_comparator (
    .clk(clk),
    .rst_n(rst_n),
    .valid_in(valid_in),
    .level(level),
    .upper_threshold(upper_threshold),
    .lower_threshold(lower_threshold),
    .valid_out(valid_stage1),
    .threshold_exceeded(threshold_exceeded_stage1),
    .threshold_cleared(threshold_cleared_stage1)
  );
  
  // 阶段2: 复位控制
  reset_controller_pipelined u_reset_controller (
    .clk(clk),
    .rst_n(rst_n),
    .valid_in(valid_stage1),
    .threshold_exceeded(threshold_exceeded_stage1),
    .threshold_cleared(threshold_cleared_stage1),
    .valid_out(valid_out),
    .reset_out(reset_out)
  );
  
endmodule

// 流水线化的阈值比较器子模块
module threshold_comparator_pipelined (
  input wire clk,
  input wire rst_n,
  input wire valid_in,
  input wire [7:0] level,
  input wire [7:0] upper_threshold,
  input wire [7:0] lower_threshold,
  output reg valid_out,
  output reg threshold_exceeded,
  output reg threshold_cleared
);
  // 流水线寄存器
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      threshold_exceeded <= 1'b0;
      threshold_cleared <= 1'b0;
      valid_out <= 1'b0;
    end else begin
      if (valid_in) begin
        // 注册比较结果
        threshold_exceeded <= (level > upper_threshold);
        threshold_cleared <= (level < lower_threshold);
      end
      valid_out <= valid_in; // 传递有效信号
    end
  end
  
endmodule

// 流水线化的复位控制器子模块
module reset_controller_pipelined (
  input wire clk,
  input wire rst_n,
  input wire valid_in,
  input wire threshold_exceeded,
  input wire threshold_cleared,
  output reg valid_out,
  output reg reset_out
);
  // 流水线寄存器和状态逻辑
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      reset_out <= 1'b0;
      valid_out <= 1'b0;
    end else begin
      valid_out <= valid_in; // 传递有效信号
      
      if (valid_in) begin
        if (!reset_out && threshold_exceeded)
          reset_out <= 1'b1;
        else if (reset_out && threshold_cleared)
          reset_out <= 1'b0;
      end
    end
  end
  
endmodule