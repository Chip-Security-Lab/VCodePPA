//SystemVerilog
module prio_enc_dir_ctl #(parameter N=8)(
  input clk, rst_n,
  input dir, // 0:LSB-first 1:MSB-first
  input [N-1:0] req,
  input valid_in,
  output valid_out,
  output reg [$clog2(N)-1:0] index
);

  // 阶段1: 检测传入的请求并选择优先级策略
  reg [N-1:0] req_stage1;
  reg dir_stage1;
  reg valid_stage1;
  
  // 阶段2: 计算结果的中间阶段
  reg [(N/2)-1:0] upper_has_req_stage2, lower_has_req_stage2;
  reg [N-1:0] req_stage2;
  reg dir_stage2;
  reg valid_stage2;
  
  // 阶段3: 最终确定索引值
  reg [$clog2(N)-1:0] index_msb_stage3, index_lsb_stage3;
  reg dir_stage3;
  reg valid_stage3;
  
  // Stage 1 - 请求接收与方向选择
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      req_stage1 <= 0;
      dir_stage1 <= 0;
      valid_stage1 <= 0;
    end else begin
      req_stage1 <= req;
      dir_stage1 <= dir;
      valid_stage1 <= valid_in;
    end
  end
  
  // Stage 2 - 请求分组和预处理
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      upper_has_req_stage2 <= 0;
      lower_has_req_stage2 <= 0;
      req_stage2 <= 0;
      dir_stage2 <= 0;
      valid_stage2 <= 0;
    end else begin
      req_stage2 <= req_stage1;
      dir_stage2 <= dir_stage1;
      valid_stage2 <= valid_stage1;
      
      // 预计算高半部分和低半部分是否有请求
      upper_has_req_stage2 <= {(N/2){1'b0}};
      lower_has_req_stage2 <= {(N/2){1'b0}};
      
      for (integer i = 0; i < N/2; i = i + 1) begin
        upper_has_req_stage2[i] <= req_stage1[i+(N/2)];
        lower_has_req_stage2[i] <= req_stage1[i];
      end
    end
  end
  
  // Stage 3 - 确定最终优先级索引
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      index_msb_stage3 <= 0;
      index_lsb_stage3 <= 0;
      dir_stage3 <= 0;
      valid_stage3 <= 0;
    end else begin
      dir_stage3 <= dir_stage2;
      valid_stage3 <= valid_stage2;
      
      // 计算MSB优先索引
      index_msb_stage3 <= 0;
      for (integer i = N-1; i >= 0; i = i - 1) begin
        if (req_stage2[i]) 
          index_msb_stage3 <= i[$clog2(N)-1:0];
      end
      
      // 计算LSB优先索引
      index_lsb_stage3 <= 0;
      for (integer i = 0; i < N; i = i + 1) begin
        if (req_stage2[i]) 
          index_lsb_stage3 <= i[$clog2(N)-1:0];
      end
    end
  end
  
  // 输出阶段 - 选择最终结果
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      index <= 0;
    end else begin
      if (valid_stage3) begin
        index <= dir_stage3 ? index_msb_stage3 : index_lsb_stage3;
      end
    end
  end
  
  // 输出有效信号
  assign valid_out = valid_stage3;

endmodule