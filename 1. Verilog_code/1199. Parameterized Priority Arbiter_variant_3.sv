//SystemVerilog
//IEEE 1364-2005 Verilog
module param_priority_arbiter #(
  parameter REQ_CNT = 8,
  parameter PRIO_WIDTH = 3
)(
  input clk, reset,
  input [REQ_CNT-1:0] requests,
  input [PRIO_WIDTH-1:0] priorities [REQ_CNT-1:0],
  output reg [REQ_CNT-1:0] grants
);

  // 组合逻辑信号声明
  wire [PRIO_WIDTH-1:0] highest_prio_comb;
  wire [3:0] selected_comb;
  wire [REQ_CNT-1:0] grants_comb;
  
  // 组合逻辑模块实例化
  priority_finder #(
    .REQ_CNT(REQ_CNT),
    .PRIO_WIDTH(PRIO_WIDTH)
  ) priority_logic (
    .requests(requests),
    .priorities(priorities),
    .highest_prio(highest_prio_comb),
    .selected(selected_comb)
  );
  
  // 组合逻辑产生下一个时钟周期的grant信号
  assign grants_comb = |requests ? (1'b1 << selected_comb) : {REQ_CNT{1'b0}};
  
  // 时序逻辑 - 寄存器更新
  always @(posedge clk) begin
    if (reset) 
      grants <= {REQ_CNT{1'b0}};
    else
      grants <= grants_comb;
  end
  
endmodule

// 纯组合逻辑模块 - 寻找最高优先级请求
module priority_finder #(
  parameter REQ_CNT = 8,
  parameter PRIO_WIDTH = 3
)(
  input [REQ_CNT-1:0] requests,
  input [PRIO_WIDTH-1:0] priorities [REQ_CNT-1:0],
  output reg [PRIO_WIDTH-1:0] highest_prio,
  output reg [3:0] selected
);
  
  integer i;
  
  always @(*) begin
    highest_prio = {PRIO_WIDTH{1'b0}};
    selected = 4'b0;
    
    for (i = 0; i < REQ_CNT; i = i + 1) begin
      if (requests[i] && priorities[i] > highest_prio) begin
        highest_prio = priorities[i];
        selected = i;
      end
    end
  end
  
endmodule