//SystemVerilog
// 顶层模块
module lru_arbiter #(parameter CLIENTS=4) (
  input clock, reset,
  input [CLIENTS-1:0] requests,
  output [CLIENTS-1:0] grants
);
  // 客户端计数器接线
  wire [CLIENTS*2-1:0] client_counts [CLIENTS-1:0];
  // 选择逻辑接线
  wire [7:0] highest_count;
  wire [$clog2(CLIENTS)-1:0] selected_client;
  wire valid_request;

  // 计数器管理器子模块
  counter_manager #(
    .CLIENTS(CLIENTS)
  ) counter_mgr_inst (
    .clock(clock),
    .reset(reset),
    .requests(requests),
    .grants(grants),
    .client_counts(client_counts),
    .selected_client(selected_client),
    .valid_request(valid_request)
  );

  // 优先级选择器子模块
  priority_selector #(
    .CLIENTS(CLIENTS)
  ) priority_sel_inst (
    .requests(requests),
    .client_counts(client_counts),
    .highest_count(highest_count),
    .selected_client(selected_client),
    .valid_request(valid_request)
  );

  // 授权生成器子模块
  grant_generator #(
    .CLIENTS(CLIENTS)
  ) grant_gen_inst (
    .clock(clock),
    .reset(reset),
    .selected_client(selected_client),
    .valid_request(valid_request),
    .grants(grants)
  );

endmodule

// 计数器管理器子模块 - 负责计数器的更新和重置
module counter_manager #(parameter CLIENTS=4) (
  input clock, reset,
  input [CLIENTS-1:0] requests,
  input [CLIENTS-1:0] grants,
  output reg [CLIENTS*2-1:0] client_counts [CLIENTS-1:0],
  input [$clog2(CLIENTS)-1:0] selected_client,
  input valid_request
);
  // 纯时序逻辑
  integer i;

  always @(posedge clock) begin
    if (reset) begin
      for (i = 0; i < CLIENTS; i = i + 1) 
        client_counts[i] <= 0;
    end else begin
      // 增加所有计数器
      for (i = 0; i < CLIENTS; i = i + 1) 
        client_counts[i] <= client_counts[i] + 1;
      
      // 如果有有效请求，重置选中客户端的计数器
      if (valid_request)
        client_counts[selected_client] <= 0;
    end
  end
endmodule

// 优先级选择器子模块 - 找出优先级最高的客户端 (纯组合逻辑)
module priority_selector #(parameter CLIENTS=4) (
  input [CLIENTS-1:0] requests,
  input [CLIENTS*2-1:0] client_counts [CLIENTS-1:0],
  output [7:0] highest_count,
  output [$clog2(CLIENTS)-1:0] selected_client,
  output valid_request
);
  // 纯组合逻辑 - 移除了clock和reset端口
  integer i;
  reg [7:0] highest_count_comb;
  reg [$clog2(CLIENTS)-1:0] selected_client_comb;
  
  // 将valid_request实现为简单组合逻辑
  assign valid_request = |requests;
  
  // 使用连续赋值替代always块
  always @(*) begin
    highest_count_comb = 0;
    selected_client_comb = 0;
    
    for (i = 0; i < CLIENTS; i = i + 1) begin
      if (requests[i] && client_counts[i] > highest_count_comb) begin
        highest_count_comb = client_counts[i];
        selected_client_comb = i;
      end
    end
  end
  
  // 连接组合逻辑输出
  assign highest_count = highest_count_comb;
  assign selected_client = selected_client_comb;
endmodule

// 授权生成器子模块 - 生成授权信号
module grant_generator #(parameter CLIENTS=4) (
  input clock, reset,
  input [$clog2(CLIENTS)-1:0] selected_client,
  input valid_request,
  output reg [CLIENTS-1:0] grants
);
  // 组合逻辑部分 - 计算下一个授权值
  wire [CLIENTS-1:0] next_grants;
  
  // 组合逻辑生成器
  assign next_grants = valid_request ? (1'b1 << selected_client) : {CLIENTS{1'b0}};

  // 时序逻辑部分 - 寄存授权值
  always @(posedge clock) begin
    if (reset) begin
      grants <= {CLIENTS{1'b0}};
    end else begin
      grants <= next_grants;
    end
  end
endmodule