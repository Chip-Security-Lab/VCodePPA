//SystemVerilog
// SystemVerilog - IEEE 1364-2005 standard
// Top level module
module RD9(
  input  logic clk,
  input  logic aresetn,
  input  logic toggle_en,
  output logic out_signal
);

  // Internal signals for module interconnection
  logic toggle_state;
  logic next_out;
  
  // Instantiate toggle state controller
  toggle_controller u_toggle_controller (
    .clk          (clk),
    .aresetn      (aresetn),
    .toggle_en    (toggle_en),
    .toggle_state (toggle_state)
  );
  
  // Instantiate output logic module
  output_logic u_output_logic (
    .clk          (clk),
    .aresetn      (aresetn),
    .toggle_state (toggle_state),
    .out_signal   (out_signal),
    .next_out     (next_out)
  );
  
  // Instantiate next state calculator
  next_state_calculator u_next_state_calculator (
    .toggle_state (toggle_state),
    .out_signal   (out_signal),
    .next_out     (next_out)
  );

endmodule

// Toggle state controller module
module toggle_controller (
  input  logic clk,
  input  logic aresetn,
  input  logic toggle_en,
  output logic toggle_state
);

  // Register for the toggle state
  always_ff @(posedge clk or negedge aresetn) begin
    if (!aresetn) 
      toggle_state <= 1'b0;
    else 
      toggle_state <= toggle_en;
  end

endmodule

// Next state calculator module
module next_state_calculator (
  input  logic toggle_state,
  input  logic out_signal,
  output logic next_out
);

  // Explicit multiplexer implementation to replace ternary operator
  // MUX selection: toggle_state
  // Data inputs: ~out_signal (when toggle_state=1) and out_signal (when toggle_state=0)
  logic inverted_out;
  assign inverted_out = ~out_signal;
  
  // 2-to-1 multiplexer
  always_comb begin
    case (toggle_state)
      1'b1: next_out = inverted_out;
      1'b0: next_out = out_signal;
      default: next_out = out_signal; // Default case for X or Z input
    endcase
  end

endmodule

// Output logic module
module output_logic (
  input  logic clk,
  input  logic aresetn,
  input  logic toggle_state,
  input  logic next_out,
  output logic out_signal
);

  // Output register
  always_ff @(posedge clk or negedge aresetn) begin
    if (!aresetn) 
      out_signal <= 1'b0;
    else 
      out_signal <= next_out;
  end

endmodule