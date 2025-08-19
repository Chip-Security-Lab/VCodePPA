module glitch_filter_reset #(
  parameter GLITCH_CYCLES = 3
) (
  input wire clk,
  input wire noisy_rst,
  output reg clean_rst
);
  reg [1:0] state;
  reg [$clog2(GLITCH_CYCLES)-1:0] counter;
  
  always @(posedge clk) begin
    case (state)
      2'b00: if (noisy_rst) begin counter <= 0; state <= 2'b01; end
      2'b01: if (!noisy_rst) state <= 2'b00;
             else if (counter == GLITCH_CYCLES-1) 
               begin clean_rst <= 1'b1; state <= 2'b10; end
             else counter <= counter + 1;
      2'b10: if (!noisy_rst) begin counter <= 0; state <= 2'b11; end
      2'b11: if (noisy_rst) state <= 2'b10;
             else if (counter == GLITCH_CYCLES-1) 
               begin clean_rst <= 1'b0; state <= 2'b00; end
             else counter <= counter + 1;
    endcase
  end
endmodule