module can_status_monitor(
  input wire clk, rst_n,
  input wire tx_active, rx_active,
  input wire error_detected, bus_off,
  input wire [7:0] tx_err_count, rx_err_count,
  output reg [2:0] node_state,
  output reg [15:0] frames_sent, frames_received,
  output reg [15:0] errors_detected
);
  localparam ERROR_ACTIVE=0, ERROR_PASSIVE=1, BUS_OFF=2;
  reg prev_tx_active, prev_rx_active, prev_error;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      node_state <= ERROR_ACTIVE;
      frames_sent <= 0;
      frames_received <= 0;
      errors_detected <= 0;
    end else begin
      prev_tx_active <= tx_active;
      prev_rx_active <= rx_active;
      prev_error <= error_detected;
      
      if (!prev_tx_active && tx_active) frames_sent <= frames_sent + 1;
      if (!prev_rx_active && rx_active) frames_received <= frames_received + 1;
      if (!prev_error && error_detected) errors_detected <= errors_detected + 1;
      
      node_state <= bus_off ? BUS_OFF : 
                   (tx_err_count > 127 || rx_err_count > 127) ? ERROR_PASSIVE : ERROR_ACTIVE;
    end
  end
endmodule