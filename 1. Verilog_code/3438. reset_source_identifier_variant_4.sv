//SystemVerilog
module reset_source_identifier (
  input wire clk,
  input wire sys_reset,
  input wire pwr_reset,
  input wire wdt_reset,
  input wire sw_reset,
  output reg [3:0] reset_source
);
  // 复位信号组合
  wire [3:0] reset_signals;
  assign reset_signals = {sys_reset, sw_reset, wdt_reset, pwr_reset};
  
  always @(posedge clk) begin
    if (pwr_reset) begin
      // pwr_reset优先级最高
      reset_source <= 4'h1;
    end
    else if (wdt_reset) begin
      // wdt_reset次之
      reset_source <= 4'h2;
    end
    else if (sw_reset) begin
      // sw_reset再次
      reset_source <= 4'h3;
    end
    else if (sys_reset) begin
      // sys_reset最后
      reset_source <= 4'h4;
    end
    else begin
      // 无复位信号
      reset_source <= 4'h0;
    end
  end
endmodule