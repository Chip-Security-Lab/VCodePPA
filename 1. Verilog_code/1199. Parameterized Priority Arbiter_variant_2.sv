//SystemVerilog
module param_priority_arbiter #(
  parameter REQ_CNT = 8,
  parameter PRIO_WIDTH = 3
)(
  input clk, reset,
  input [REQ_CNT-1:0] requests,
  input [PRIO_WIDTH-1:0] priorities [REQ_CNT-1:0],
  output reg [REQ_CNT-1:0] grants
);
  // 流水线阶段信号
  wire [REQ_CNT-1:0] requests_stage1;
  wire [PRIO_WIDTH-1:0] priorities_stage1 [REQ_CNT-1:0];
  
  // 组合逻辑输出信号
  wire [3:0] highest_req_idx_stage2;
  wire has_request_stage2;
  wire [REQ_CNT-1:0] next_grants_stage3;
  
  // 实例化流水线优先级选择器
  pipelined_priority_selector #(
    .REQ_CNT(REQ_CNT),
    .PRIO_WIDTH(PRIO_WIDTH)
  ) prio_selector_inst (
    .clk(clk),
    .reset(reset),
    .requests(requests),
    .priorities(priorities),
    .highest_req_idx(highest_req_idx_stage2),
    .has_request(has_request_stage2),
    .next_grants(next_grants_stage3)
  );

  // 输出阶段 - 流水线最后一级
  always @(posedge clk)
    grants <= reset ? {REQ_CNT{1'b0}} : next_grants_stage3;
endmodule

// 流水线化的优先级选择器
module pipelined_priority_selector #(
  parameter REQ_CNT = 8,
  parameter PRIO_WIDTH = 3
)(
  input clk, reset,
  input [REQ_CNT-1:0] requests,
  input [PRIO_WIDTH-1:0] priorities [REQ_CNT-1:0],
  output reg [3:0] highest_req_idx,
  output reg has_request,
  output reg [REQ_CNT-1:0] next_grants
);
  // 第一级流水线寄存器 - 请求和优先级缓存
  reg [REQ_CNT-1:0] requests_stage1;
  reg [PRIO_WIDTH-1:0] priorities_stage1 [REQ_CNT-1:0];
  
  // 第二级流水线寄存器 - 优先级比较中间结果
  reg [PRIO_WIDTH-1:0] highest_prio_stage2_1;
  reg [3:0] highest_idx_stage2_1;
  reg [PRIO_WIDTH-1:0] highest_prio_stage2_2;
  reg [3:0] highest_idx_stage2_2;
  reg has_request_stage1;

  // 第三级流水线寄存器 - 高优先级确认
  reg [PRIO_WIDTH-1:0] highest_prio_stage3;
  reg [3:0] highest_idx_stage3;
  reg has_request_stage2;
  
  integer i, j;
  
  // 流水线第一级 - 输入寄存
  always @(posedge clk) begin
    if (reset) begin
      requests_stage1 <= {REQ_CNT{1'b0}};
      has_request_stage1 <= 1'b0;
      for (i = 0; i < REQ_CNT; i = i + 1) begin
        priorities_stage1[i] <= {PRIO_WIDTH{1'b0}};
      end
    end else begin
      requests_stage1 <= requests;
      has_request_stage1 <= |requests;
      for (i = 0; i < REQ_CNT; i = i + 1) begin
        priorities_stage1[i] <= priorities[i];
      end
    end
  end
  
  // 流水线第二级 - 分段优先级比较
  // 将请求分成两半进行并行比较
  always @(posedge clk) begin
    if (reset) begin
      highest_prio_stage2_1 <= {PRIO_WIDTH{1'b0}};
      highest_idx_stage2_1 <= 4'b0;
      highest_prio_stage2_2 <= {PRIO_WIDTH{1'b0}};
      highest_idx_stage2_2 <= 4'b0;
      has_request_stage2 <= 1'b0;
    end else begin
      // 处理前半部分请求
      highest_prio_stage2_1 <= {PRIO_WIDTH{1'b0}};
      highest_idx_stage2_1 <= 4'b0;
      for (i = 0; i < REQ_CNT/2; i = i + 1) begin
        if (requests_stage1[i] && (priorities_stage1[i] > highest_prio_stage2_1)) begin
          highest_prio_stage2_1 <= priorities_stage1[i];
          highest_idx_stage2_1 <= i;
        end
      end
      
      // 处理后半部分请求
      highest_prio_stage2_2 <= {PRIO_WIDTH{1'b0}};
      highest_idx_stage2_2 <= 4'b0;
      for (i = REQ_CNT/2; i < REQ_CNT; i = i + 1) begin
        if (requests_stage1[i] && (priorities_stage1[i] > highest_prio_stage2_2)) begin
          highest_prio_stage2_2 <= priorities_stage1[i];
          highest_idx_stage2_2 <= i;
        end
      end
      
      has_request_stage2 <= has_request_stage1;
    end
  end
  
  // 流水线第三级 - 最终优先级确认
  always @(posedge clk) begin
    if (reset) begin
      highest_prio_stage3 <= {PRIO_WIDTH{1'b0}};
      highest_idx_stage3 <= 4'b0;
      has_request <= 1'b0;
    end else begin
      // 比较两半部分的结果，选出最高优先级
      if (highest_prio_stage2_1 >= highest_prio_stage2_2) begin
        highest_prio_stage3 <= highest_prio_stage2_1;
        highest_idx_stage3 <= highest_idx_stage2_1;
      end else begin
        highest_prio_stage3 <= highest_prio_stage2_2;
        highest_idx_stage3 <= highest_idx_stage2_2;
      end
      has_request <= has_request_stage2;
    end
  end
  
  // 流水线第四级 - 生成授权信号
  always @(posedge clk) begin
    if (reset) begin
      highest_req_idx <= 4'b0;
      next_grants <= {REQ_CNT{1'b0}};
    end else begin
      highest_req_idx <= highest_idx_stage3;
      next_grants <= has_request ? ({{(REQ_CNT-1){1'b0}}, 1'b1} << highest_idx_stage3) : {REQ_CNT{1'b0}};
    end
  end
endmodule