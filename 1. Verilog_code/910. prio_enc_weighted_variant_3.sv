//SystemVerilog
module prio_enc_weighted #(parameter N=4)(
  input clk,
  input rst,  // 添加复位信号
  input valid_in,  // 输入有效信号
  input [N-1:0] req,
  input [N-1:0] weight,
  output reg valid_out,  // 输出有效信号
  output reg [1:0] max_idx
);

  // 第一级流水线寄存器
  reg valid_stage1;
  reg [N-1:0] req_stage1;
  reg [N-1:0] weight_stage1;
  reg [1:0] idx_stage1 [0:N/2-1];
  reg [7:0] weight_stage1_values [0:N/2-1];
  
  // 第二级流水线寄存器
  reg valid_stage2;
  reg [1:0] idx_stage2 [0:1];
  reg [7:0] weight_stage2 [0:1];
  
  integer i;
  
  // 第一级流水线：分成两组并行比较
  always @(posedge clk) begin
    if (rst) begin
      valid_stage1 <= 0;
      req_stage1 <= 0;
      weight_stage1 <= 0;
      for (i = 0; i < N/2; i = i + 1) begin
        idx_stage1[i] <= 0;
        weight_stage1_values[i] <= 0;
      end
    end 
    else begin
      valid_stage1 <= valid_in;
      req_stage1 <= req;
      weight_stage1 <= weight;
      
      // 处理前半部分
      idx_stage1[0] <= 0;
      weight_stage1_values[0] <= 0;
      for (i = 0; i < N/2; i = i + 1) begin
        if (req[i] && weight[i] > weight_stage1_values[0]) begin
          weight_stage1_values[0] <= weight[i];
          idx_stage1[0] <= i;
        end
      end
      
      // 处理后半部分
      idx_stage1[1] <= N/2;
      weight_stage1_values[1] <= 0;
      for (i = N/2; i < N; i = i + 1) begin
        if (req[i] && weight[i] > weight_stage1_values[1]) begin
          weight_stage1_values[1] <= weight[i];
          idx_stage1[1] <= i;
        end
      end
    end
  end
  
  // 第二级流水线：比较两组结果
  always @(posedge clk) begin
    if (rst) begin
      valid_stage2 <= 0;
      idx_stage2[0] <= 0;
      idx_stage2[1] <= 0;
      weight_stage2[0] <= 0;
      weight_stage2[1] <= 0;
    end
    else begin
      valid_stage2 <= valid_stage1;
      idx_stage2[0] <= idx_stage1[0];
      idx_stage2[1] <= idx_stage1[1];
      weight_stage2[0] <= weight_stage1_values[0];
      weight_stage2[1] <= weight_stage1_values[1];
    end
  end
  
  // 最终结果输出
  always @(posedge clk) begin
    if (rst) begin
      valid_out <= 0;
      max_idx <= 0;
    end
    else begin
      valid_out <= valid_stage2;
      
      if (weight_stage2[0] >= weight_stage2[1]) begin
        max_idx <= idx_stage2[0];
      end
      else begin
        max_idx <= idx_stage2[1];
      end
    end
  end
  
endmodule