//SystemVerilog
module power_on_reset #(
  parameter POR_CYCLES = 32
) (
  input wire clk,
  input wire power_good,
  output reg system_rst_n
);
  reg [$clog2(POR_CYCLES)-1:0] por_counter;
  wire [$clog2(POR_CYCLES)-1:0] target_value;
  reg [$clog2(POR_CYCLES)-1:0] remaining_cycles;
  reg comparison_result;
  
  // 使用补码加法实现减法：remaining_cycles = POR_CYCLES-1 - por_counter
  assign target_value = POR_CYCLES-1;
  
  always @(posedge clk or negedge power_good) begin
    if (!power_good) begin
      por_counter <= {$clog2(POR_CYCLES){1'b0}};
      remaining_cycles <= target_value;
      comparison_result <= 1'b0;
      system_rst_n <= 1'b0;
    end else begin
      if (!comparison_result) begin
        por_counter <= por_counter + 1'b1;
        remaining_cycles <= target_value + (~(por_counter + 1'b1)) + 1'b1;
        comparison_result <= (target_value + (~(por_counter + 1'b1)) + 1'b1) == {$clog2(POR_CYCLES){1'b0}};
      end
      system_rst_n <= comparison_result;
    end
  end
endmodule