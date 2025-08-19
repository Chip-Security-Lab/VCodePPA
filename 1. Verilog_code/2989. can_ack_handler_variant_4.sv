//SystemVerilog
module can_ack_handler(
  input wire clk, rst_n,
  input wire can_rx, can_tx,
  input wire in_ack_slot, in_ack_delim,
  output reg ack_error,
  output reg can_ack_drive
);
  // Intermediate registers for improved timing
  reg can_rx_r, can_tx_r;
  reg in_ack_slot_r, in_ack_delim_r;
  
  // Register inputs to reduce input-to-register delay
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      can_rx_r <= 1'b1;         // Default recessive state
      can_tx_r <= 1'b1;         // Default recessive state
      in_ack_slot_r <= 1'b0;
      in_ack_delim_r <= 1'b0;
    end else begin
      can_rx_r <= can_rx;
      can_tx_r <= can_tx;
      in_ack_slot_r <= in_ack_slot;
      in_ack_delim_r <= in_ack_delim;
    end
  end
  
  // Main logic using registered inputs
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ack_error <= 0;
      can_ack_drive <= 0;
    end else begin
      // When receiving, drive ACK slot low (dominant)
      if (in_ack_slot_r && !can_tx_r) begin  // Only in receive mode
        can_ack_drive <= 1;
      end else begin
        can_ack_drive <= 0;
      end
      
      // When transmitting, check for ACK
      if (in_ack_slot_r && can_tx_r && can_rx_r) begin
        ack_error <= 1;  // No acknowledgment received
      end else if (in_ack_delim_r) begin
        ack_error <= 0;  // Reset for next frame
      end
    end
  end
endmodule