//SystemVerilog
module pipelined_parity_gen(
  input clk, rst_n,
  input [31:0] data_in,
  output reg parity_out
);

  // 子模块接口信号
  wire parity_lo, parity_hi;
  
  // 实例化低16位奇偶校验子模块
  parity_calc #(
    .WIDTH(16)
  ) parity_lo_inst (
    .clk(clk),
    .rst_n(rst_n),
    .data(data_in[15:0]),
    .parity(parity_lo)
  );
  
  // 实例化高16位奇偶校验子模块
  parity_calc #(
    .WIDTH(16)
  ) parity_hi_inst (
    .clk(clk),
    .rst_n(rst_n),
    .data(data_in[31:16]),
    .parity(parity_hi)
  );
  
  // 顶层模块中的最终奇偶校验计算
  always @(posedge clk) begin
    if (!rst_n) begin
      parity_out <= 1'b0;
    end else begin
      parity_out <= parity_lo ^ parity_hi;
    end
  end
endmodule

// 参数化奇偶校验计算子模块
module parity_calc #(
  parameter WIDTH = 16
)(
  input clk, rst_n,
  input [WIDTH-1:0] data,
  output reg parity
);

  always @(posedge clk) begin
    if (!rst_n) begin
      parity <= 1'b0;
    end else begin
      parity <= ^data;
    end
  end
endmodule