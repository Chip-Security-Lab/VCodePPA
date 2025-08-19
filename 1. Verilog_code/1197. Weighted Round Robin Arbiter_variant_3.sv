//SystemVerilog
module weighted_rr_arbiter(
  input wire clk, rst,
  input wire [2:0] req,
  input wire [1:0] weights [2:0],  // 每个请求者的权重
  output reg [2:0] grant
);
  // 阶段1信号
  reg [2:0] req_stage1;
  reg [1:0] weights_stage1 [2:0];
  reg [1:0] current_stage1;
  reg [2:0] count_stage1 [2:0];
  reg valid_stage1;

  // 阶段2信号
  reg [2:0] req_stage2;
  reg [1:0] weights_stage2 [2:0];
  reg [1:0] current_stage2;
  reg [2:0] count_stage2 [2:0];
  reg valid_stage2;
  reg matched_stage2;
  reg [1:0] next_current_stage2;
  reg [2:0] next_count_stage2 [2:0];

  // 中间变量，用于拆分复杂条件
  reg current_req_active;          // 当前请求是否激活
  reg current_count_valid;         // 当前计数是否有效
  reg [1:0] next_requester;        // 下一个请求者

  // 状态寄存器
  reg [1:0] current;
  reg [2:0] count [2:0];

  // 阶段1：请求捕获和初始处理
  always @(posedge clk) begin
    if (rst) begin
      req_stage1 <= 3'b0;
      current_stage1 <= 2'b0;
      valid_stage1 <= 1'b0;
      
      // 使用循环初始化数组，提高代码可读性
      for (int i = 0; i < 3; i++) begin
        count_stage1[i] <= 3'b0;
        weights_stage1[i] <= 2'b0;
      end
    end 
    else begin
      req_stage1 <= req;
      current_stage1 <= current;
      valid_stage1 <= 1'b1;
      
      // 使用循环更新数组，提高代码可读性
      for (int i = 0; i < 3; i++) begin
        count_stage1[i] <= count[i];
        weights_stage1[i] <= weights[i];
      end
    end
  end

  // 阶段2：仲裁逻辑
  always @(posedge clk) begin
    if (rst) begin
      req_stage2 <= 3'b0;
      current_stage2 <= 2'b0;
      valid_stage2 <= 1'b0;
      matched_stage2 <= 1'b0;
      next_current_stage2 <= 2'b0;
      
      // 使用循环初始化数组
      for (int i = 0; i < 3; i++) begin
        count_stage2[i] <= 3'b0;
        weights_stage2[i] <= 2'b0;
        next_count_stage2[i] <= 3'b0;
      end
    end 
    else begin
      // 基础信号传递
      req_stage2 <= req_stage1;
      current_stage2 <= current_stage1;
      valid_stage2 <= valid_stage1;
      
      // 使用循环更新数组
      for (int i = 0; i < 3; i++) begin
        count_stage2[i] <= count_stage1[i];
        weights_stage2[i] <= weights_stage1[i];
      end
      
      // 初始化下一个计数值
      for (int i = 0; i < 3; i++) begin
        next_count_stage2[i] <= count_stage1[i];
      end
      
      if (valid_stage1) begin
        // 将复杂条件分解为简单判断
        current_req_active = req_stage1[current_stage1];
        current_count_valid = count_stage1[current_stage1] < weights_stage1[current_stage1];
        next_requester = (current_stage1 + 1'b1) % 3;
        
        // 第一级条件：当前请求是否激活
        if (current_req_active) begin
          // 第二级条件：当前计数是否有效
          if (current_count_valid) begin
            matched_stage2 <= 1'b1;
            next_count_stage2[current_stage1] <= count_stage1[current_stage1] + 1'b1;
            next_current_stage2 <= current_stage1;
          end
          else begin
            matched_stage2 <= 1'b0;
            next_count_stage2[current_stage1] <= 3'b0;
            next_current_stage2 <= next_requester;
          end
        end
        else begin
          matched_stage2 <= 1'b0;
          next_count_stage2[current_stage1] <= 3'b0;
          next_current_stage2 <= next_requester;
        end
      end
    end
  end

  // 最终阶段：授权输出和状态更新
  always @(posedge clk) begin
    if (rst) begin
      grant <= 3'b0;
      current <= 2'b0;
      
      // 使用循环初始化计数数组
      for (int i = 0; i < 3; i++) begin
        count[i] <= 3'b0;
      end
    end 
    else begin
      // 默认不授权
      grant <= 3'b0;
      
      if (valid_stage2) begin
        // 简化条件结构
        if (matched_stage2) begin
          grant[current_stage2] <= 1'b1;
        end
        
        // 更新状态
        current <= next_current_stage2;
        
        // 使用循环更新计数数组
        for (int i = 0; i < 3; i++) begin
          count[i] <= next_count_stage2[i];
        end
      end
    end
  end
endmodule