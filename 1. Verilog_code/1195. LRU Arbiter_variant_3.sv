//SystemVerilog
//======================================================================
//======================================================================
module lru_arbiter #(
  parameter CLIENTS = 4,
  parameter COUNT_WIDTH = 8  // 定义计数器宽度，优化资源使用
) (
  input                  clock,
  input                  reset,
  input  [CLIENTS-1:0]   requests,
  output [CLIENTS-1:0]   grants
);

  // Internal registers for pipelined data flow
  reg [CLIENTS-1:0]      grants_reg;
  reg [COUNT_WIDTH-1:0]  lru_counter [CLIENTS-1:0];  // 计数器数组
  
  // Pipeline stage 1: Request processing and highest priority identification
  reg [CLIENTS-1:0]      valid_requests;
  reg [COUNT_WIDTH-1:0]  stage1_highest_count;
  reg [$clog2(CLIENTS)-1:0] stage1_highest_idx;
  reg                    request_valid;
  
  // Pipeline stage 2: Grant generation and counter update control
  reg [$clog2(CLIENTS)-1:0] stage2_highest_idx;
  reg                    stage2_request_valid;
  
  // Client processing loops
  integer i;
  
  // Stage 1: Request evaluation and priority determination
  always @(posedge clock) begin
    if (reset) begin
      valid_requests <= {CLIENTS{1'b0}};
      stage1_highest_count <= {COUNT_WIDTH{1'b0}};
      stage1_highest_idx <= {$clog2(CLIENTS){1'b0}};
      request_valid <= 1'b0;
    end else begin
      // Capture valid requests and find highest priority
      valid_requests <= requests;
      stage1_highest_count <= {COUNT_WIDTH{1'b0}};
      stage1_highest_idx <= {$clog2(CLIENTS){1'b0}};
      request_valid <= |requests;
      
      // 扁平化优先级确定逻辑
      for (i = 0; i < CLIENTS; i = i + 1) begin
        if (requests[i] && lru_counter[i] > stage1_highest_count) begin
          stage1_highest_count <= lru_counter[i];
          stage1_highest_idx <= i[$clog2(CLIENTS)-1:0];
        end
      end
    end
  end
  
  // Stage 2: Forward pipeline and prepare grant signal
  always @(posedge clock) begin
    if (reset) begin
      stage2_highest_idx <= {$clog2(CLIENTS){1'b0}};
      stage2_request_valid <= 1'b0;
    end else begin
      stage2_highest_idx <= stage1_highest_idx;
      stage2_request_valid <= request_valid;
    end
  end
  
  // Counter management and grants generation - 扁平化结构
  always @(posedge clock) begin
    // 默认状态：无授权
    grants_reg <= {CLIENTS{1'b0}};
    
    // 重置情况
    if (reset) begin
      for (i = 0; i < CLIENTS; i = i + 1) begin
        lru_counter[i] <= {COUNT_WIDTH{1'b0}};
      end
      grants_reg <= {CLIENTS{1'b0}};
    end 
    // 有效请求且无重置
    else if (stage2_request_valid && !reset) begin
      // 更新所有计数器
      for (i = 0; i < CLIENTS; i = i + 1) begin
        if (i == stage2_highest_idx) begin
          // 被选中的客户端重置计数器
          lru_counter[i] <= {COUNT_WIDTH{1'b0}};
        end else begin
          // 其他客户端递增计数器
          lru_counter[i] <= lru_counter[i] + 1'b1;
        end
      end
      // 为选中的客户端生成授权信号
      grants_reg[stage2_highest_idx] <= 1'b1;
    end
    // 无有效请求且无重置
    else if (!stage2_request_valid && !reset) begin
      // 所有计数器递增
      for (i = 0; i < CLIENTS; i = i + 1) begin
        lru_counter[i] <= lru_counter[i] + 1'b1;
      end
    end
  end
  
  // Output assignment
  assign grants = grants_reg;

endmodule