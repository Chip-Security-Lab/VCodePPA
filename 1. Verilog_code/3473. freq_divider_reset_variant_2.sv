//SystemVerilog
module freq_divider_reset #(parameter DIVISOR = 10)(
  input clk_in, reset,
  output reg clk_out
);
  reg [$clog2(DIVISOR)-1:0] counter;
  
  always @(posedge clk_in) begin
    // 使用2位控制变量: {reset, counter==DIVISOR-1}
    case ({reset, counter == DIVISOR - 1})
      2'b10, 
      2'b11: begin // 复位情况（无论counter值如何）
        counter <= 0;
        clk_out <= 0;
      end
      
      2'b01: begin // 不复位且计数器达到分频值
        counter <= 0;
        clk_out <= ~clk_out;
      end
      
      2'b00: begin // 不复位且计数器未达到分频值
        counter <= counter + 1;
      end
    endcase
  end
endmodule