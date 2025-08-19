//SystemVerilog
// SystemVerilog

// 顶层模块
module round_robin_arbiter #(parameter WIDTH=4) (
  input wire clock, reset,
  input wire [WIDTH-1:0] request,
  output wire [WIDTH-1:0] grant
);
  wire [WIDTH-1:0] masked_req;
  wire [WIDTH-1:0] priority_req;
  wire [WIDTH-1:0] prefix_subtractor_output;
  wire [WIDTH-1:0] mask, nxt_mask;

  // 实例化请求掩码模块
  request_masking #(.WIDTH(WIDTH)) req_mask_inst (
    .request(request),
    .mask(mask),
    .masked_req(masked_req),
    .priority_req(priority_req)
  );

  // 实例化前缀减法器模块
  prefix_subtractor #(.WIDTH(WIDTH)) prefix_sub_inst (
    .priority_req(priority_req),
    .subtractor_output(prefix_subtractor_output)
  );

  // 实例化授权生成模块
  grant_generator #(.WIDTH(WIDTH)) grant_gen_inst (
    .masked_req(masked_req),
    .request(request),
    .prefix_subtractor_output(prefix_subtractor_output),
    .grant(grant),
    .nxt_mask(nxt_mask)
  );

  // 实例化掩码更新模块
  mask_update #(.WIDTH(WIDTH)) mask_update_inst (
    .clock(clock),
    .reset(reset),
    .nxt_mask(nxt_mask),
    .mask(mask)
  );
endmodule

// 请求掩码模块 - 处理请求掩码逻辑
module request_masking #(parameter WIDTH=4) (
  input wire [WIDTH-1:0] request,
  input wire [WIDTH-1:0] mask,
  output wire [WIDTH-1:0] masked_req,
  output wire [WIDTH-1:0] priority_req
);
  // 掩码应用于请求信号
  assign masked_req = request & ~mask;
  
  // 确定优先级请求 - 如果掩码请求有效则使用它，否则使用原始请求
  assign priority_req = |masked_req ? masked_req : request;
endmodule

// 前缀减法器模块 - 实现并行前缀减法运算
module prefix_subtractor #(parameter WIDTH=4) (
  input wire [WIDTH-1:0] priority_req,
  output wire [WIDTH-1:0] subtractor_output
);
  // 使用并行前缀减法器实现（减1操作）生成独热码
  // 利用补码算术特性: x & (-x) 提取最低有效位
  assign subtractor_output = priority_req & (~priority_req + 1'b1);
endmodule

// 授权生成模块 - 生成最终的授权信号
module grant_generator #(parameter WIDTH=4) (
  input wire [WIDTH-1:0] masked_req,
  input wire [WIDTH-1:0] request,
  input wire [WIDTH-1:0] prefix_subtractor_output,
  output wire [WIDTH-1:0] grant,
  output wire [WIDTH-1:0] nxt_mask
);
  wire [WIDTH-1:0] grant_masked, grant_unmasked;
  reg [WIDTH-1:0] next_mask_reg;
  
  // 根据掩码请求和原始请求分别计算授权
  assign grant_masked = |masked_req ? prefix_subtractor_output : {WIDTH{1'b0}};
  assign grant_unmasked = |masked_req ? {WIDTH{1'b0}} : (|request ? prefix_subtractor_output : {WIDTH{1'b0}});
  
  // 合并两种授权情况
  assign grant = grant_masked | grant_unmasked;
  
  // 计算下一个掩码值
  always @(*) begin
    if (|grant)
      next_mask_reg = {grant[WIDTH-2:0], grant[WIDTH-1]};
    else
      next_mask_reg = nxt_mask;
  end
  
  assign nxt_mask = next_mask_reg;
endmodule

// 掩码更新模块 - 处理掩码的时序更新
module mask_update #(parameter WIDTH=4) (
  input wire clock, reset,
  input wire [WIDTH-1:0] nxt_mask,
  output reg [WIDTH-1:0] mask
);
  // 在时钟上升沿更新掩码
  always @(posedge clock) begin
    if (reset)
      mask <= {WIDTH{1'b0}};
    else
      mask <= nxt_mask;
  end
endmodule