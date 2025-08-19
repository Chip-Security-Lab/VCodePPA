//SystemVerilog
module RD8 #(parameter SIZE=4)(
  input wire clk,
  input wire rst,
  output reg [SIZE-1:0] ring
);

  // Pipeline registers
  reg [SIZE-1:0] next_state;
  reg valid;
  
  // Combined pipeline logic with single always block
  always @(posedge clk) begin
    if (rst) begin
      // Reset all pipeline stages simultaneously
      next_state <= 'b1;
      valid <= 1'b0;
      ring <= 'b1;
    end
    else begin
      // Stage 1: Calculate next state
      next_state <= {ring[SIZE-2:0], ring[SIZE-1]};
      valid <= 1'b1;
      
      // Update output stage based on valid signal
      if (valid) begin
        ring <= next_state;
      end
    end
  end

endmodule