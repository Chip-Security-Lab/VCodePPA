//SystemVerilog
module reset_startup_delay (
  input wire clk,
  input wire reset_n,
  output reg system_ready
);
  reg [7:0] delay_counter;
  
  // 简化计数器逻辑 - 直接增加计数器而不使用复杂的CLA结构
  wire [7:0] next_counter = delay_counter + 8'h01;

  always @(posedge clk) begin
    if (!reset_n) begin
      delay_counter <= 8'h00;
      system_ready <= 1'b0;
    end
    else begin
      if (delay_counter < 8'hFF)
        delay_counter <= next_counter;
      
      if (delay_counter == 8'hFE)  // 提前一个周期设置ready信号
        system_ready <= 1'b1;
    end
  end
endmodule