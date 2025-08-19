module power_on_reset #(
  parameter POR_CYCLES = 32
) (
  input wire clk,
  input wire power_good,
  output reg system_rst_n
);
  reg [$clog2(POR_CYCLES)-1:0] por_counter;
  
  always @(posedge clk or negedge power_good) begin
    if (!power_good) begin
      por_counter <= 0;
      system_rst_n <= 1'b0;
    end else begin
      if (por_counter < POR_CYCLES-1) 
        por_counter <= por_counter + 1;
      system_rst_n <= (por_counter == POR_CYCLES-1);
    end
  end
endmodule