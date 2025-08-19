//SystemVerilog
// 顶层模块
module parity_with_error_latch(
  input clk, rst, clear_error,
  input [7:0] data,
  input parity_in,
  output error_latched
);
  // 内部连线
  wire current_error;

  // 实例化奇偶校验子模块
  parity_checker u_parity_checker (
    .data(data),
    .parity_in(parity_in),
    .current_error(current_error)
  );

  // 实例化错误锁存控制子模块
  error_latch_controller u_error_latch (
    .clk(clk),
    .rst(rst),
    .clear_error(clear_error),
    .current_error(current_error),
    .error_latched(error_latched)
  );

endmodule

// 奇偶校验计算子模块
module parity_checker(
  input [7:0] data,
  input parity_in,
  output current_error
);
  // 计算数据奇偶校验并与输入奇偶性比较
  assign current_error = (^data) ^ parity_in;
endmodule

// 错误锁存控制子模块
module error_latch_controller(
  input clk,
  input rst,
  input clear_error,
  input current_error,
  output reg error_latched
);
  // 错误锁存逻辑
  always @(posedge clk) begin
    case({rst, clear_error, current_error})
      3'b100: error_latched <= 1'b0;  // 复位
      3'b010: error_latched <= 1'b0;  // 清除错误
      3'b001: error_latched <= 1'b1;  // 检测到错误
      default: error_latched <= error_latched;  // 保持当前状态
    endcase
  end
endmodule