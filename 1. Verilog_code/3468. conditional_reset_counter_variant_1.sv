//SystemVerilog
module conditional_reset_counter #(parameter WIDTH = 12)(
  input clk, reset_n, condition, enable,
  output reg [WIDTH-1:0] value
);
  // Control signals
  reg [1:0] control_signals;
  
  // Define control signal encoding
  always @(*) begin
    case ({!reset_n, condition, enable})
      3'b1_?_?: control_signals = 2'b00; // Reset active
      3'b0_1_1: control_signals = 2'b00; // Conditional reset
      3'b0_0_1: control_signals = 2'b01; // Counting enabled
      default:  control_signals = 2'b10; // Hold value
    endcase
  end
  
  always @(posedge clk) begin
    case (control_signals)
      2'b00: value <= {WIDTH{1'b0}};    // Reset counter
      2'b01: value <= value + 1'b1;     // Increment counter
      2'b10: value <= value;            // Hold value
      default: value <= {WIDTH{1'b0}};  // Default to reset
    endcase
  end
endmodule