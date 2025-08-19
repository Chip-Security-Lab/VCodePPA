//SystemVerilog
module reset_sync_mem_wr(
  input  wire clk,
  input  wire rst_n,
  input  wire wr_data,
  input  wire valid_in,    // 输入数据有效信号
  output wire ready_in,    // 输入就绪信号
  output reg  mem_out,
  output reg  valid_out    // 输出数据有效信号
);
  
  // 流水线阶段1寄存器和控制信号
  reg mem_stage1;
  reg valid_stage1;
  
  // 流水线阶段2寄存器和控制信号
  reg mem_stage2;
  reg valid_stage2;
  
  // 流水线控制逻辑 - 所有阶段都准备好接收数据
  assign ready_in = 1'b1;  // 此简单设计总是准备好接收新数据
  
  // 流水线阶段1逻辑
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      mem_stage1 <= 1'b0;
      valid_stage1 <= 1'b0;
    end else begin
      mem_stage1 <= wr_data;        // 数据流经流水线
      valid_stage1 <= valid_in;     // 控制信号流经流水线
    end
  end
  
  // 流水线阶段2逻辑
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      mem_stage2 <= 1'b0;
      valid_stage2 <= 1'b0;
    end else begin
      mem_stage2 <= mem_stage1;        // 数据流经流水线
      valid_stage2 <= valid_stage1;    // 控制信号流经流水线
    end
  end
  
  // 输出阶段
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      mem_out <= 1'b0;
      valid_out <= 1'b0;
    end else begin
      mem_out <= mem_stage2;         // 最终输出
      valid_out <= valid_stage2;     // 输出有效信号
    end
  end
  
endmodule