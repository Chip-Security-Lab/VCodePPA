//SystemVerilog
module debounce_reset_monitor #(
  parameter DEBOUNCE_CYCLES = 8
) (
  input wire clk,
  input wire reset_in,
  output reg reset_out
);
  // Move counter and state signals to after combinational logic
  reg [$clog2(DEBOUNCE_CYCLES)-1:0] counter;
  
  // Synchronization registers for input
  reg reset_in_ff1, reset_in_ff2;
  
  // Use enumerated type for states
  localparam RESET_CHANGED = 2'b00;
  localparam COUNTING     = 2'b01;
  localparam STABLE       = 2'b10;
  
  // Intermediate combinational signals
  wire reset_changed = reset_in_ff2 != reset_in_ff1;
  wire still_counting = counter < DEBOUNCE_CYCLES-1;
  wire [1:0] state_sel = {reset_changed, still_counting};
  
  always @(posedge clk) begin
    // Input synchronization - moved forward
    reset_in_ff1 <= reset_in;
    reset_in_ff2 <= reset_in_ff1;
    
    // State machine logic - retimed
    case (state_sel)
      2'b10:   begin // reset changed
        counter <= 0;
      end
      
      2'b01:   begin // still counting
        counter <= counter + 1;
      end
      
      2'b00:   begin // stable state reached
        reset_out <= reset_in_ff2;
      end
      
      2'b11:   begin // should not happen, but handle as reset changed
        counter <= 0;
      end
    endcase
  end
endmodule