//SystemVerilog
module temperature_reset #(
  parameter HOT_THRESHOLD = 8'hC0
) (
  input  wire       clk,
  input  wire [7:0] temperature,
  input  wire       rst_n,
  output wire       temp_reset
);
  
  // Internal connection signals
  wire comparison_result;
  
  // Instantiate temperature comparison module
  temp_comparator #(
    .THRESHOLD(HOT_THRESHOLD)
  ) comp_unit (
    .clk          (clk),
    .rst_n        (rst_n),
    .temperature  (temperature),
    .comp_result  (comparison_result)
  );
  
  // Instantiate reset generation module
  reset_generator reset_unit (
    .clk          (clk),
    .rst_n        (rst_n),
    .comp_result  (comparison_result),
    .temp_reset   (temp_reset)
  );
  
endmodule

// Temperature comparison module
module temp_comparator #(
  parameter THRESHOLD = 8'hC0
) (
  input  wire       clk,
  input  wire       rst_n,
  input  wire [7:0] temperature,
  output reg        comp_result
);
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      comp_result <= 1'b0;
    else
      comp_result <= (temperature > THRESHOLD);
  end
  
endmodule

// Reset signal generation module
module reset_generator (
  input  wire clk,
  input  wire rst_n,
  input  wire comp_result,
  output reg  temp_reset
);
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      temp_reset <= 1'b0;
    else
      temp_reset <= comp_result;
  end
  
endmodule