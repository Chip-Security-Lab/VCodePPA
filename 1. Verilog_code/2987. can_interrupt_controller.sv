module can_interrupt_controller(
  input wire clk, rst_n,
  input wire tx_done, rx_done, error_detected, bus_off,
  input wire [3:0] interrupt_mask,
  output reg interrupt,
  output reg [3:0] interrupt_status
);
  reg [3:0] pending_interrupts;
  reg prev_tx_done, prev_rx_done, prev_error, prev_bus_off;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pending_interrupts <= 0;
      interrupt <= 0;
      interrupt_status <= 0;
      prev_tx_done <= 0;
      prev_rx_done <= 0;
      prev_error <= 0;
      prev_bus_off <= 0;
    end else begin
      prev_tx_done <= tx_done;
      prev_rx_done <= rx_done;
      prev_error <= error_detected;
      prev_bus_off <= bus_off;
      
      if (!prev_tx_done && tx_done) pending_interrupts[0] <= 1;
      if (!prev_rx_done && rx_done) pending_interrupts[1] <= 1;
      if (!prev_error && error_detected) pending_interrupts[2] <= 1;
      if (!prev_bus_off && bus_off) pending_interrupts[3] <= 1;
      
      interrupt_status <= pending_interrupts;
      interrupt <= |(pending_interrupts & interrupt_mask);
    end
  end
endmodule