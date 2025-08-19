//SystemVerilog
module parity_with_error_injection(
  input  wire        clk,
  input  wire        rst_n,
  input  wire [15:0] data_in,
  input  wire        error_inject,
  output reg         parity
);

  // Internal signals
  reg [15:0] data_reg;
  reg        error_reg;
  wire       parity_calc;
  
  // Stage 1: Input registration
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data_reg <= 16'h0000;
      error_reg <= 1'b0;
    end else begin
      data_reg <= data_in;
      error_reg <= error_inject;
    end
  end
  
  // Stage 2: Parity calculation
  assign parity_calc = ^data_reg;
  
  // Stage 3: Error injection and output registration
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      parity <= 1'b0;
    end else begin
      parity <= parity_calc ^ error_reg;
    end
  end

endmodule