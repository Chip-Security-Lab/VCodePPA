//SystemVerilog
// 顶层模块
module sync_odd_parity_gen(
  input clock, resetn,
  input [7:0] din,
  output p_out
);
  // 内部连线
  wire parity_bit;
  
  // 奇偶校验计算子模块
  parity_calculator parity_calc_inst (
    .data_in(din),
    .odd_parity(parity_bit)
  );
  
  // 输出寄存器子模块
  output_synchronizer output_sync_inst (
    .clock(clock),
    .resetn(resetn),
    .parity_in(parity_bit),
    .parity_out(p_out)
  );
endmodule

// 奇偶校验计算子模块
module parity_calculator(
  input [7:0] data_in,
  output odd_parity
);
  // 计算奇校验位（输入位的异或结果取反）
  assign odd_parity = ~(^data_in);
endmodule

// 输出同步器子模块
module output_synchronizer(
  input clock, resetn,
  input parity_in,
  output reg parity_out
);
  always @(posedge clock) begin
    parity_out <= (!resetn) ? 1'b0 : parity_in;
  end
endmodule