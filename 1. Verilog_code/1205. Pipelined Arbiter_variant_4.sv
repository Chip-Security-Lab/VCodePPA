//SystemVerilog
module pipelined_arbiter #(parameter WIDTH=4) (
  input clk, rst,
  input [WIDTH-1:0] req_in,
  input valid_in,
  output reg valid_out,
  output reg [WIDTH-1:0] grant_out,
  output reg ready_out
);
  // 流水线阶段控制信号
  reg valid_stage1, valid_stage2, valid_stage3;
  reg ready_stage1, ready_stage2, ready_stage3;
  
  // 流水线阶段数据寄存器
  reg [WIDTH-1:0] req_stage1, req_stage2, req_stage3;
  reg [WIDTH-1:0] priority_stage1, priority_stage2, priority_stage3;
  
  // 组合逻辑部分 - 拆分为三个均衡的计算阶段
  wire [WIDTH-1:0] mask_stage1;
  wire [WIDTH-1:0] mask_stage2;
  wire [WIDTH-1:0] final_grant;
  
  // 第一阶段优先级逻辑计算 - 准备掩码
  assign mask_stage1[0] = 1'b0;
  assign mask_stage1[1] = req_stage1[0];
  assign mask_stage1[2] = req_stage1[1];
  assign mask_stage1[3] = req_stage1[2];
  
  // 第二阶段优先级逻辑 - 计算完整掩码
  assign mask_stage2[0] = 1'b0;
  assign mask_stage2[1] = priority_stage1[0];
  assign mask_stage2[2] = priority_stage1[0] | priority_stage1[1];
  assign mask_stage2[3] = priority_stage1[0] | priority_stage1[1] | priority_stage1[2];
  
  // 第三阶段优先级逻辑 - 生成最终授权信号
  assign final_grant[0] = req_stage3[0];
  assign final_grant[1] = req_stage3[1] & ~mask_stage2[1];
  assign final_grant[2] = req_stage3[2] & ~mask_stage2[2];
  assign final_grant[3] = req_stage3[3] & ~mask_stage2[3];
  
  // 复位逻辑 - 用于统一处理所有信号的复位
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      // 复位所有流水线控制信号
      valid_stage1 <= 1'b0;
      valid_stage2 <= 1'b0;
      valid_stage3 <= 1'b0;
      valid_out <= 1'b0;
      
      ready_stage1 <= 1'b1;
      ready_stage2 <= 1'b1;
      ready_stage3 <= 1'b1;
      ready_out <= 1'b1;
      
      // 复位所有数据寄存器
      req_stage1 <= {WIDTH{1'b0}};
      req_stage2 <= {WIDTH{1'b0}};
      req_stage3 <= {WIDTH{1'b0}};
      
      priority_stage1 <= {WIDTH{1'b0}};
      priority_stage2 <= {WIDTH{1'b0}};
      priority_stage3 <= {WIDTH{1'b0}};
      
      grant_out <= {WIDTH{1'b0}};
    end
  end
  
  // 有效信号传播逻辑 - 向后传播有效信号
  always @(posedge clk) begin
    if (!rst) begin
      valid_stage1 <= valid_in & ready_stage1;
      valid_stage2 <= valid_stage1 & ready_stage2;
      valid_stage3 <= valid_stage2 & ready_stage3;
      valid_out <= valid_stage3;
    end
  end
  
  // 就绪信号传播逻辑 - 向前传播就绪信号(反压机制)
  always @(posedge clk) begin
    if (!rst) begin
      ready_stage3 <= ready_out;
      ready_stage2 <= ready_stage3 | ~valid_stage3;
      ready_stage1 <= ready_stage2 | ~valid_stage2;
      ready_out <= 1'b1;  // 假设输出总是就绪
    end
  end
  
  // 流水线第一阶段数据处理
  always @(posedge clk) begin
    if (!rst && valid_in && ready_stage1) begin
      req_stage1 <= req_in;
    end
  end
  
  // 流水线第二阶段数据处理
  always @(posedge clk) begin
    if (!rst && valid_stage1 && ready_stage2) begin
      req_stage2 <= req_stage1;
      priority_stage1[0] <= req_stage1[0];
      priority_stage1[1] <= req_stage1[1];
      priority_stage1[2] <= req_stage1[2];
      priority_stage1[3] <= req_stage1[3];
    end
  end
  
  // 流水线第三阶段数据处理
  always @(posedge clk) begin
    if (!rst && valid_stage2 && ready_stage3) begin
      req_stage3 <= req_stage2;
      priority_stage2 <= priority_stage1;
    end
  end
  
  // 输出阶段数据处理
  always @(posedge clk) begin
    if (!rst && valid_stage3 && ready_out) begin
      grant_out <= |req_stage3 ? final_grant : {WIDTH{1'b0}};
    end
  end
  
endmodule