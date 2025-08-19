//SystemVerilog
module prio_enc_weighted #(parameter N=4)(
  input clk,
  input [N-1:0] req,
  input [N-1:0] weight,
  output reg [1:0] max_idx
);
  // 内部信号定义
  reg [7:0] max_weight_comb;
  reg [1:0] max_idx_comb;
  
  // 组合逻辑部分 - 计算最大权重和索引
  always @(*) begin
    max_weight_comb = 8'd0;
    max_idx_comb = 2'd0;
  end
  
  // 独立的比较逻辑 - 索引0
  always @(*) begin
    if(req[0] && weight[0] > max_weight_comb) begin
      max_weight_comb = weight[0];
      max_idx_comb = 2'd0;
    end
  end
  
  // 独立的比较逻辑 - 索引1
  always @(*) begin
    if(req[1] && weight[1] > max_weight_comb) begin
      max_weight_comb = weight[1];
      max_idx_comb = 2'd1;
    end
  end
  
  // 独立的比较逻辑 - 索引2
  always @(*) begin
    if(req[2] && weight[2] > max_weight_comb) begin
      max_weight_comb = weight[2];
      max_idx_comb = 2'd2;
    end
  end
  
  // 独立的比较逻辑 - 索引3
  always @(*) begin
    if(req[3] && weight[3] > max_weight_comb) begin
      max_weight_comb = weight[3];
      max_idx_comb = 2'd3;
    end
  end
  
  // 时序逻辑部分 - 在时钟边沿更新输出
  always @(posedge clk) begin
    max_idx <= max_idx_comb;
  end
endmodule