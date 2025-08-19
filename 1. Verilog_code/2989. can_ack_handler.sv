module can_ack_handler(
  input wire clk, rst_n,
  input wire can_rx, can_tx,
  input wire in_ack_slot, in_ack_delim,
  output reg ack_error,
  output reg can_ack_drive
);
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ack_error <= 0;
      can_ack_drive <= 0;
    end else begin
      // When receiving, drive ACK slot low (dominant)
      if (in_ack_slot && !can_tx) begin  // Only in receive mode
        can_ack_drive <= 1;
      end else begin
        can_ack_drive <= 0;
      end
      
      // When transmitting, check for ACK
      if (in_ack_slot && can_tx && can_rx) begin
        ack_error <= 1;  // No acknowledgment received
      end else if (in_ack_delim) begin
        ack_error <= 0;  // Reset for next frame
      end
    end
  end
endmodule