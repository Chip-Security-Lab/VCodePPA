//SystemVerilog
module daisy_chain_arbiter(
  input clk, reset,
  input [3:0] request,
  output [3:0] grant
);
  // 请求信号寄存
  reg [3:0] request_reg;
  
  // 提前计算的chain信号
  reg [4:0] chain;
  
  // 提前计算的grant信号
  reg [3:0] grant_reg;
  
  // 有效信号
  reg valid;
  
  // 捕获请求信号
  always @(posedge clk) begin
    if (reset) begin
      request_reg <= 4'h0;
      valid <= 1'b0;
    end
    else begin
      request_reg <= request;
      valid <= 1'b1;
    end
  end
  
  // 计算chain信号，使用简化的布尔表达式
  always @(posedge clk) begin
    if (reset) begin
      chain <= 5'h0;
    end
    else begin
      // 使用级联方式简化表达式
      chain[0] <= 1'b1;  // 第一级始终具有优先权
      chain[1] <= ~request[0];
      chain[2] <= ~request[0] & ~request[1];
      chain[3] <= ~request[0] & ~request[1] & ~request[2];
      chain[4] <= ~request[0] & ~request[1] & ~request[2] & ~request[3];
    end
  end
  
  // 使用简化的grant计算逻辑
  always @(posedge clk) begin
    if (reset) begin
      grant_reg <= 4'h0;
    end
    else if (valid) begin
      grant_reg[0] <= request_reg[0];
      grant_reg[1] <= request_reg[1] & chain[1];
      grant_reg[2] <= request_reg[2] & chain[2];
      grant_reg[3] <= request_reg[3] & chain[3];
    end
  end
  
  // 输出赋值
  assign grant = grant_reg;
  
endmodule