//SystemVerilog
module reset_stretcher #(
  parameter STRETCH_CYCLES = 16
) (
  input wire clk,
  input wire reset_in,
  output reg reset_out
);
  reg [$clog2(STRETCH_CYCLES):0] counter;
  
  // Borrow generation signals for parallel borrow subtractor
  wire [$clog2(STRETCH_CYCLES):0] borrow;
  wire [$clog2(STRETCH_CYCLES):0] counter_next;
  
  // Generate borrow signals for each bit
  assign borrow[0] = 1'b1; // Initial borrow-in for subtraction by 1
  
  genvar i;
  generate
    for (i = 0; i < $clog2(STRETCH_CYCLES); i = i + 1) begin : gen_borrow
      assign borrow[i+1] = ~counter[i] & borrow[i];
    end
  endgenerate
  
  // Calculate next counter value using parallel borrow subtractor
  generate
    for (i = 0; i < $clog2(STRETCH_CYCLES)+1; i = i + 1) begin : gen_subtractor
      assign counter_next[i] = counter[i] ^ borrow[i];
    end
  endgenerate
  
  always @(posedge clk) begin
    case ({reset_in, counter > 0})
      2'b10, 2'b11: counter <= STRETCH_CYCLES;  // reset_in active
      2'b01:        counter <= counter_next;    // counter > 0, use parallel borrow subtractor
      2'b00:        counter <= 0;               // maintain counter value
    endcase
    
    reset_out <= (counter > 0) | reset_in;
  end
endmodule