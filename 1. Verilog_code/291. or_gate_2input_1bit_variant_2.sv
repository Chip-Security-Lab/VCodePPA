//SystemVerilog
// SystemVerilog
// Top-level module for a 2-input OR gate with registered output
module or_gate_2input_1bit_registered (
    input wire clk,
    input wire rst_n,
    input wire i_a,
    input wire i_b,
    output reg o_y
);

  // Internal wire to hold the combinational OR result
  wire or_result_comb;

  // Instantiate the basic OR function module
  basic_or_function u_basic_or_function (
      .i_a (i_a),
      .i_b (i_b),
      .o_y (or_result_comb)
  );

  // Register the combinational result to create a pipeline stage
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      o_y <= 1'b0;
    end else begin
      o_y <= or_result_comb;
    end
  end

endmodule

// Sub-module implementing the basic 2-input OR function
module basic_or_function (
    input wire i_a,
    input wire i_b,
    output wire o_y
);

  assign o_y = i_a | i_b;

endmodule