//SystemVerilog
//IEEE 1364-2005 Verilog
module masked_priority_arbiter(
  input wire clk, rst_n,
  input wire [3:0] req,
  input wire [3:0] mask,
  output reg [3:0] grant
);
  wire [3:0] masked_req;
  reg [3:0] next_grant;

  // 使用单个表达式计算屏蔽后的请求
  assign masked_req = req & ~mask;
  
  // 扁平化的组合逻辑确定下一个授权状态
  always @(*) begin
    // 默认无授权
    next_grant = 4'h0;
    
    // 扁平化的优先级结构，使用逻辑与(&&)组合条件
    if (masked_req[0]) 
      next_grant = 4'b0001;
    else if (masked_req[1]) 
      next_grant = 4'b0010;
    else if (masked_req[2]) 
      next_grant = 4'b0100;
    else if (masked_req[3]) 
      next_grant = 4'b1000;
    else if (masked_req == 4'h0 && req != 4'h0 && !mask[0] && req[0])
      next_grant = 4'b0001;
    else if (masked_req == 4'h0 && req != 4'h0 && !mask[1] && req[1])
      next_grant = 4'b0010;
    else if (masked_req == 4'h0 && req != 4'h0 && !mask[2] && req[2])
      next_grant = 4'b0100;
    else if (masked_req == 4'h0 && req != 4'h0 && !mask[3] && req[3])
      next_grant = 4'b1000;
  end

  // 时序逻辑
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
      grant <= 4'h0;
    else 
      grant <= next_grant;
  end
endmodule