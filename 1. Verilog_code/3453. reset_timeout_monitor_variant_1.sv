//SystemVerilog
module reset_timeout_monitor (
  input wire clk,
  input wire reset_n,
  output reg reset_timeout_error
);
  // 定义内部寄存器和状态
  reg [7:0] timeout;
  
  // 组合逻辑 - 状态确定
  wire [1:0] next_state;
  
  // 组合逻辑 - 状态计算
  assign next_state = (!reset_n) ? 2'd0 :
                     (timeout < 8'hFF) ? 2'd1 : 2'd2;
  
  // 组合逻辑 - 下一个值计算
  wire [7:0] next_timeout;
  wire next_reset_timeout_error;
  
  // 组合逻辑部分 - 计算下一个状态的输出
  assign next_timeout = (next_state == 2'd0) ? 8'd0 :
                        (next_state == 2'd1) ? timeout + 8'd1 : 
                        timeout;
  
  assign next_reset_timeout_error = (next_state == 2'd0) ? 1'b0 :
                                   (next_state == 2'd2) ? 1'b1 :
                                   reset_timeout_error;
  
  // 时序逻辑部分 - 更新寄存器
  always @(posedge clk) begin
    timeout <= next_timeout;
    reset_timeout_error <= next_reset_timeout_error;
  end
endmodule