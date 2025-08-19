//SystemVerilog
// SystemVerilog
module power_on_reset #(
  parameter POR_CYCLES = 32
) (
  input wire clk,
  input wire power_good,
  output reg system_rst_n
);
  // Registered version of power_good input
  reg power_good_reg;
  reg [$clog2(POR_CYCLES)-1:0] por_counter;
  
  // Register the input first to reduce input-to-register delay
  always @(posedge clk) begin
    power_good_reg <= power_good;
  end
  
  // Main control logic with registered input using case statement
  always @(posedge clk) begin
    case (power_good_reg)
      1'b0: begin
        por_counter <= 0;
        system_rst_n <= 1'b0;
      end
      1'b1: begin
        case (por_counter < POR_CYCLES-1)
          1'b1: begin
            por_counter <= por_counter + 1;
            system_rst_n <= 1'b0;
          end
          1'b0: begin
            system_rst_n <= 1'b1;
          end
        endcase
      end
    endcase
  end
endmodule