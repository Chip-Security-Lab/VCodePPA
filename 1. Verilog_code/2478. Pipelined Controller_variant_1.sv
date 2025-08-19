//SystemVerilog
module pipelined_intr_ctrl(
  input clk, rst_n,
  input [15:0] intr_req,
  input ready,
  output reg [3:0] intr_id,
  output reg valid
);
  // 重排组合逻辑后的信号
  reg [3:0] highest_pri_id;
  reg req_valid;
  
  // 优化的流水线寄存器
  reg [15:0] stage1_req;
  reg [3:0] stage2_id;
  reg stage2_valid;
  reg transfer_complete;
  
  // 传输完成信号生成 - 前移到组合逻辑中
  always @(*) begin
    transfer_complete = (valid && ready) || !valid;
  end
  
  // 优化的第一阶段：直接处理输入请求
  always @(*) begin
    req_valid = |intr_req;
    casez (intr_req)
      16'b1???????????????: highest_pri_id = 4'd15;
      16'b01??????????????: highest_pri_id = 4'd14;
      16'b001?????????????: highest_pri_id = 4'd13;
      16'b0001????????????: highest_pri_id = 4'd12;
      16'b00001???????????: highest_pri_id = 4'd11;
      16'b000001??????????: highest_pri_id = 4'd10;
      16'b0000001?????????: highest_pri_id = 4'd9;
      16'b00000001????????: highest_pri_id = 4'd8;
      16'b000000001???????: highest_pri_id = 4'd7;
      16'b0000000001??????: highest_pri_id = 4'd6;
      16'b00000000001?????: highest_pri_id = 4'd5;
      16'b000000000001????: highest_pri_id = 4'd4;
      16'b0000000000001???: highest_pri_id = 4'd3;
      16'b00000000000001??: highest_pri_id = 4'd2;
      16'b000000000000001?: highest_pri_id = 4'd1;
      16'b0000000000000001: highest_pri_id = 4'd0;
      default: highest_pri_id = 4'd0;
    endcase
  end
  
  // 第一阶段流水线 - 移到组合逻辑后
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      stage1_req <= 16'h0;
      stage2_id <= 4'h0;
      stage2_valid <= 1'b0;
    end
    else if (transfer_complete) begin
      // 存储当前输入供后续使用
      stage1_req <= intr_req;
      // 直接将组合逻辑结果进入流水线
      stage2_id <= highest_pri_id;
      stage2_valid <= req_valid;
    end
  end
  
  // 输出阶段 - 简化控制逻辑
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      intr_id <= 4'h0;
      valid <= 1'b0;
    end 
    else if (ready || !valid) begin
      // 流水线更新输出
      intr_id <= stage2_id;
      valid <= stage2_valid;
    end
  end
  
endmodule