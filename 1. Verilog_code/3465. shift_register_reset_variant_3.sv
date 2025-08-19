//SystemVerilog
module shift_register_reset #(parameter WIDTH = 16)(
  input clk, reset, shift_en, data_in,
  input [7:0] subtrahend, minuend,
  output reg [WIDTH-1:0] shift_data,
  output reg [7:0] difference
);
  
  // 优化：直接使用减法操作代替补码加法
  // 这减少了计算两次补码的逻辑门数量
  
  always @(posedge clk) begin
    if (reset) begin
      shift_data <= {WIDTH{1'b0}};
      difference <= 8'b0;
    end else begin
      // 移位寄存器操作 - 使用非阻塞赋值保持时序一致性
      if (shift_en)
        shift_data <= {shift_data[WIDTH-2:0], data_in};
      
      // 使用直接减法替代补码加法，降低逻辑复杂度
      difference <= minuend - subtrahend;
    end
  end
endmodule