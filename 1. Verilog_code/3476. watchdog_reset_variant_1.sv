//SystemVerilog
`timescale 1ns / 1ps
`default_nettype none

module watchdog_reset #(parameter TIMEOUT = 1000)(
  input wire clk, ext_rst_n, watchdog_clear,
  output reg watchdog_rst
);
  localparam TIMER_WIDTH = $clog2(TIMEOUT);
  reg [TIMER_WIDTH-1:0] timer;
  
  // 查找表辅助减法器实现
  wire [7:0] subtrahend;
  wire [7:0] lut_result;
  wire [7:0] minuend;
  wire borrow_out;
  
  // 减法器查找表实例化
  subtractor_lut sub_unit (
    .minuend(minuend),
    .subtrahend(subtrahend),
    .result(lut_result),
    .borrow_out(borrow_out)
  );
  
  // 连接到子模块
  assign subtrahend = timer[7:0];
  assign minuend = (TIMEOUT - 1) & 8'hFF;
  
  // 比较逻辑 - 使用查找表辅助减法器的结果
  wire timer_lt_timeout = (timer[TIMER_WIDTH-1:8] < (TIMEOUT - 1) >> 8) ||
                         ((timer[TIMER_WIDTH-1:8] == (TIMEOUT - 1) >> 8) && 
                          !borrow_out);
  
  always @(posedge clk or negedge ext_rst_n) begin
    if (!ext_rst_n) begin
      timer <= 0;
      watchdog_rst <= 0;
    end else if (watchdog_clear) begin
      timer <= 0;
      watchdog_rst <= 0;
    end else if (timer_lt_timeout) begin
      timer <= timer + 1;
    end else begin
      watchdog_rst <= 1;
    end
  end
  
endmodule

module subtractor_lut (
  input wire [7:0] minuend,
  input wire [7:0] subtrahend,
  output wire [7:0] result,
  output wire borrow_out
);
  // 查找表实现的8位减法器
  reg [8:0] lut_memory [0:255][0:255]; // 存储所有可能的减法结果及借位
  
  // 初始化查找表
  integer i, j;
  initial begin
    for (i = 0; i < 256; i = i + 1) begin
      for (j = 0; j < 256; j = j + 1) begin
        if (i >= j)
          lut_memory[i][j] = {1'b0, i - j}; // 第9位是借位输出
        else
          lut_memory[i][j] = {1'b1, i - j}; // 执行有借位的减法
      end
    end
  end
  
  // 查找表查询
  wire [8:0] lut_result = lut_memory[minuend][subtrahend];
  
  // 输出结果和借位
  assign result = lut_result[7:0];
  assign borrow_out = lut_result[8];
  
endmodule
`default_nettype wire