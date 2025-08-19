//SystemVerilog
// 顶层模块
module RD1 #(parameter DW=8)(
  input clk, input rst,
  input [DW-1:0] din,
  output [DW-1:0] dout
);

  // 实例化数据通路子模块
  data_path #(
    .DW(DW)
  ) data_path_inst (
    .din(din),
    .dout(dout)
  );

endmodule

// 数据通路子模块 - 负责信号处理
module data_path #(parameter DW=8)(
  input [DW-1:0] din,
  output [DW-1:0] dout
);
  // 调用信号传递功能模块
  signal_transfer #(
    .DW(DW)
  ) signal_transfer_inst (
    .din(din),
    .dout(dout)
  );
endmodule

// 信号传递功能模块 - 处理数据前传
module signal_transfer #(parameter DW=8)(
  input [DW-1:0] din,
  output [DW-1:0] dout
);
  // 实现输入到输出的直通逻辑
  // 直通逻辑能够减少输入到寄存器的延迟
  // 相当于向前移动寄存器位置
  assign dout = din;
endmodule