//SystemVerilog
//IEEE 1364-2005 Verilog
module reset_sync_3stage(
  input  wire clk,
  input  wire rst_n,
  output wire synced_rst
);
  
  // 使用参数增加可配置性
  localparam NUM_STAGES = 3;
  
  // 内部连线
  wire [NUM_STAGES-1:0] next_sync_stages;
  (* dont_touch = "true" *)  // 综合指令防止优化掉同步链
  (* async_reg = "true" *)   // 提示工具这是异步寄存器，改善时序分析
  reg [NUM_STAGES-1:0] sync_stages;
  
  // 实例化组合逻辑模块
  reset_sync_comb #(
    .NUM_STAGES(NUM_STAGES)
  ) comb_logic (
    .rst_n(rst_n),
    .sync_stages(sync_stages),
    .next_sync_stages(next_sync_stages),
    .synced_rst(synced_rst)
  );
  
  // 时序逻辑部分
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sync_stages <= {NUM_STAGES{1'b0}};  // 复位时所有阶段清零
    end else begin
      sync_stages <= next_sync_stages;    // 更新为组合逻辑计算的下一状态
    end
  end
  
endmodule

// 纯组合逻辑模块
module reset_sync_comb #(
  parameter NUM_STAGES = 3
)(
  input  wire rst_n,
  input  wire [NUM_STAGES-1:0] sync_stages,
  output wire [NUM_STAGES-1:0] next_sync_stages,
  output wire synced_rst
);
  
  // 组合逻辑计算下一状态
  assign next_sync_stages = rst_n ? {sync_stages[NUM_STAGES-2:0], 1'b1} : {NUM_STAGES{1'b0}};
  
  // 输出为最后一个触发器的值
  assign synced_rst = sync_stages[NUM_STAGES-1];
  
endmodule