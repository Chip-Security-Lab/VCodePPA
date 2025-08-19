//SystemVerilog
// SystemVerilog - IEEE 1364-2005
// 顶层模块
module reset_sync_pass #(
  parameter NUM_STAGES = 2
)(
  input  wire clk,
  input  wire rst_n,
  input  wire data_in,
  input  wire valid_in,   // 输入数据有效信号
  output wire ready_out,  // 输出就绪信号
  output wire data_out,
  output wire valid_out,  // 输出数据有效信号
  input  wire ready_in    // 输入就绪信号
);
  
  wire sync_stage_out;
  wire stage1_valid;
  wire stage1_ready;
  
  // 第一级同步子模块
  sync_stage_module first_stage (
    .clk       (clk),
    .rst_n     (rst_n),
    .data_in   (data_in),
    .valid_in  (valid_in),
    .ready_out (ready_out),
    .data_out  (sync_stage_out),
    .valid_out (stage1_valid),
    .ready_in  (stage1_ready)
  );
  
  // 第二级同步子模块
  sync_stage_module second_stage (
    .clk       (clk),
    .rst_n     (rst_n),
    .data_in   (sync_stage_out),
    .valid_in  (stage1_valid),
    .ready_out (stage1_ready),
    .data_out  (data_out),
    .valid_out (valid_out),
    .ready_in  (ready_in)
  );
  
endmodule

// 同步级子模块 - 优化后版本
module sync_stage_module (
  input  wire clk,
  input  wire rst_n,
  input  wire data_in,
  input  wire valid_in,   // 输入数据有效信号
  output wire ready_out,  // 输出就绪信号
  output wire data_out,
  output reg  valid_out,  // 输出数据有效信号
  input  wire ready_in    // 输入就绪信号
);

  // 数据传输控制逻辑
  wire transfer_data;
  assign transfer_data = valid_in && ready_out;
  
  // 优化：将数据寄存器移到组合逻辑之前
  reg data_reg;
  
  // 将data_out直接连接到data_reg
  assign data_out = data_reg;
  
  // 输出就绪信号生成
  // 当下游准备好接收数据或输出无效时，可以接收新数据
  assign ready_out = !valid_out || ready_in;
  
  // 优化后的数据寄存控制 - 将数据寄存提前到valid控制之前
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data_reg <= 1'b0;
    end else if (transfer_data) begin
      // 新数据到达时立即寄存
      data_reg <= data_in;
    end
  end
  
  // 分离的有效信号控制
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      valid_out <= 1'b0;
    end else begin
      if (valid_out && ready_in) begin
        // 数据被下游接收，清除有效标志
        valid_out <= 1'b0;
      end
      
      if (transfer_data) begin
        // 新数据到达并可以被接收
        valid_out <= 1'b1;
      end
    end
  end
  
endmodule