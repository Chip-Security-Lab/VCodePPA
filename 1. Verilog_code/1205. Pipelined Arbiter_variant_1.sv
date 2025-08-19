//SystemVerilog
module pipelined_arbiter #(parameter WIDTH=4) (
  input clk, rst,
  input [WIDTH-1:0] req_in,
  output reg [WIDTH-1:0] grant_out
);
  reg [WIDTH-1:0] req_stage1, req_stage2;
  reg [WIDTH-1:0] grant_stage1, grant_stage2;
  
  // 用于优化组合逻辑的中间信号
  reg [WIDTH-1:0] next_grant;
  wire has_req;
  
  // 请求状态检测逻辑 - 转为连续赋值以减少always块
  assign has_req = |req_stage1;
  
  // 处理第一个请求的优先级
  always @(*) begin
    next_grant[0] = req_stage1[0];
  end
  
  // 处理第二个请求的优先级
  always @(*) begin
    next_grant[1] = req_stage1[1] & ~req_stage1[0];
  end
  
  // 处理第三个请求的优先级
  always @(*) begin
    next_grant[2] = req_stage1[2] & ~req_stage1[1] & ~req_stage1[0];
  end
  
  // 处理第四个请求的优先级
  always @(*) begin
    next_grant[3] = req_stage1[3] & ~req_stage1[2] & ~req_stage1[1] & ~req_stage1[0];
  end
  
  // 流水线第一阶段 - 请求寄存
  always @(posedge clk) begin
    if (rst) begin
      req_stage1 <= {WIDTH{1'b0}};
    end else begin
      req_stage1 <= req_in;
    end
  end
  
  // 流水线第一阶段 - 仲裁结果寄存
  always @(posedge clk) begin
    if (rst) begin
      grant_stage1 <= {WIDTH{1'b0}};
    end else begin
      grant_stage1 <= has_req ? next_grant : {WIDTH{1'b0}};
    end
  end
  
  // 流水线第二阶段 - 请求状态前移
  always @(posedge clk) begin
    if (rst) begin
      req_stage2 <= {WIDTH{1'b0}};
    end else begin
      req_stage2 <= req_stage1;
    end
  end
  
  // 流水线第二阶段 - 仲裁结果前移
  always @(posedge clk) begin
    if (rst) begin
      grant_stage2 <= {WIDTH{1'b0}};
    end else begin
      grant_stage2 <= grant_stage1;
    end
  end
  
  // 输出阶段
  always @(posedge clk) begin
    if (rst) begin
      grant_out <= {WIDTH{1'b0}};
    end else begin
      grant_out <= grant_stage2;
    end
  end
endmodule