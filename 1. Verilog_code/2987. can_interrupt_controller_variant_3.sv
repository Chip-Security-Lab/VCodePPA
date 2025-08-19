//SystemVerilog
module can_interrupt_controller(
  input wire clk, rst_n,
  input wire tx_done, rx_done, error_detected, bus_off,
  input wire [3:0] interrupt_mask,
  output reg interrupt,
  output reg [3:0] interrupt_status
);
  reg [3:0] pending_interrupts;
  reg [3:0] prev_status;
  wire [3:0] status_change;
  wire [3:0] masked_interrupts;
  
  // Edge detection with parallel processing
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      prev_status <= 4'b0000;
      pending_interrupts <= 4'b0000;
      interrupt_status <= 4'b0000;
      interrupt <= 1'b0;
    end else begin
      // Capture previous status values in parallel
      prev_status <= {bus_off, error_detected, rx_done, tx_done};
      
      // Update pending interrupts based on detected edges
      if (status_change[0]) pending_interrupts[0] <= 1'b1;
      if (status_change[1]) pending_interrupts[1] <= 1'b1;
      if (status_change[2]) pending_interrupts[2] <= 1'b1;
      if (status_change[3]) pending_interrupts[3] <= 1'b1;
      
      // Update output signals
      interrupt_status <= pending_interrupts;
      interrupt <= |masked_interrupts;
    end
  end
  
  // Parallel edge detection logic for all inputs
  assign status_change[0] = tx_done & ~prev_status[0];
  assign status_change[1] = rx_done & ~prev_status[1];
  assign status_change[2] = error_detected & ~prev_status[2];
  assign status_change[3] = bus_off & ~prev_status[3];
  
  // Pre-compute masked interrupts to reduce critical path
  assign masked_interrupts = pending_interrupts & interrupt_mask;
  
endmodule