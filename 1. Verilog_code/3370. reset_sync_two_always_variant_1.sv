//SystemVerilog
// Top-level module
module reset_sync_two_always (
  input  wire clk,    // 时钟输入
  input  wire rst_n,  // 低电平有效的异步复位信号
  output wire out_rst // 同步复位输出
);

  wire stage1_out;
  
  // 第一级同步器实例
  rst_sync_stage #(
    .ACTIVE_LOW(1)
  ) first_stage (
    .clk      (clk),
    .rst_n    (rst_n),
    .stage_in (1'b1),
    .stage_out(stage1_out)
  );
  
  // 第二级同步器实例
  rst_sync_stage #(
    .ACTIVE_LOW(1)
  ) second_stage (
    .clk      (clk),
    .rst_n    (rst_n),
    .stage_in (stage1_out),
    .stage_out(out_rst)
  );
  
endmodule

// 同步器单级模块
module rst_sync_stage #(
  parameter ACTIVE_LOW = 1  // 复位是否为低电平有效
)(
  input  wire clk,       // 时钟信号
  input  wire rst_n,     // 异步复位信号
  input  wire stage_in,  // 级联输入
  output reg  stage_out  // 级联输出
);
  
  // 复位条件检测
  wire reset_condition = ACTIVE_LOW ? !rst_n : rst_n;
  
  // 同步器逻辑
  (* preserve *) 
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      stage_out <= ACTIVE_LOW ? 1'b0 : 1'b1;
    else
      stage_out <= stage_in;
  end
  
endmodule