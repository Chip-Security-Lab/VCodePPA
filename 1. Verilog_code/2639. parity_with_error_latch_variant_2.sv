//SystemVerilog
module parity_with_error_latch_top(
  input clk, 
  input rst, 
  input clear_error, 
  input [7:0] data, 
  input parity_in, 
  output reg error_latched
);

  wire current_error;
  wire parity_in_buf;
  wire current_error_buf;

  // Buffer for high fanout signal parity_in
  reg parity_in_reg;
  always @(posedge clk or posedge rst) begin
    if (rst)
      parity_in_reg <= 1'b0;
    else
      parity_in_reg <= parity_in;
  end
  assign parity_in_buf = parity_in_reg;

  // Buffer for high fanout signal current_error
  reg current_error_reg;
  always @(posedge clk or posedge rst) begin
    if (rst)
      current_error_reg <= 1'b0;
    else
      current_error_reg <= current_error;
  end
  assign current_error_buf = current_error_reg;

  // Instantiate the parity checker module
  parity_checker u_parity_checker (
    .data(data),
    .parity_in(parity_in_buf),
    .current_error(current_error)
  );

  // Instantiate the error latch module
  error_latch u_error_latch (
    .clk(clk),
    .rst(rst),
    .clear_error(clear_error),
    .current_error(current_error_buf),
    .error_latched(error_latched)
  );

endmodule

module parity_checker(
  input [7:0] data,
  input parity_in,
  output wire current_error
);
  assign current_error = (^data) ^ parity_in;
endmodule

module error_latch(
  input clk,
  input rst,
  input clear_error,
  input current_error,
  output reg error_latched
);
  always @(posedge clk) begin
    case ({rst, clear_error, current_error})
      3'b100: error_latched <= 1'b0; // rst
      3'b010: error_latched <= 1'b0; // clear_error
      3'b001: error_latched <= 1'b1; // current_error
      default: error_latched <= error_latched; // retain state
    endcase
  end
endmodule