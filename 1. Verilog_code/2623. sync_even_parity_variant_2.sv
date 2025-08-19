//SystemVerilog
module sync_even_parity_valid_ready(
  input clk, rst,
  input [15:0] data,
  output reg parity,
  output reg valid,
  input ready
);
  reg [15:0] data_reg;

  always @(posedge clk) begin
    if (rst) begin
      parity <= 1'b0;
      valid <= 1'b0;
      data_reg <= 16'b0;
    end else begin
      if (!valid) begin
        data_reg <= data; // Capture data when valid is low
        valid <= 1'b1;    // Set valid high to indicate data is ready
      end
      if (valid && ready) begin
        parity <= ^data_reg; // Calculate parity when ready is high
        valid <= 1'b0;       // Clear valid after data is processed
      end
    end
  end
endmodule