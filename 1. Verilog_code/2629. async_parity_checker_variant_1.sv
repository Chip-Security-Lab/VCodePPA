//SystemVerilog

// 子模块：奇偶校验计算模块
module parity_calculator(
  input [7:0] data,
  output reg calculated_parity
);
  always @(*) begin
    calculated_parity = data[0] ^ data[1] ^ data[2] ^ data[3] ^ 
                        data[4] ^ data[5] ^ data[6] ^ data[7];
  end
endmodule

// 顶层模块：异步奇偶校验检查器
module async_parity_checker(
  input [7:0] data_recv,
  input parity_recv,
  output reg error_flag
);
  wire calculated_parity;

  // 实例化奇偶校验计算模块
  parity_calculator u_parity_calculator (
    .data(data_recv),
    .calculated_parity(calculated_parity)
  );

  always @(*) begin
    error_flag = calculated_parity ~^ parity_recv;
  end
endmodule