module freq_sensitive_reset #(
  parameter CLOCK_COUNT = 8
) (
  input wire main_clk,
  input wire ref_clk,
  output reg reset_out
);
  reg [3:0] main_counter;
  reg [3:0] ref_counter;
  reg ref_clk_sync;
  
  always @(posedge main_clk) begin
    ref_clk_sync <= ref_clk;
    if (ref_clk && !ref_clk_sync) begin
      main_counter <= 4'd0;
      ref_counter <= ref_counter + 4'd1;
    end else if (main_counter < 4'hF) begin
      main_counter <= main_counter + 4'd1;
    end
    reset_out <= (main_counter > CLOCK_COUNT);
  end
endmodule