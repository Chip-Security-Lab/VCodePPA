//SystemVerilog
module can_ack_handler(
  input wire clk, rst_n,
  input wire can_rx, can_tx,
  input wire in_ack_slot, in_ack_delim,
  output reg ack_error,
  output reg can_ack_drive
);
  // Pipeline stage 1: Input Registration
  reg in_ack_slot_stage1, in_ack_delim_stage1;
  reg can_rx_stage1, can_tx_stage1;
  reg valid_stage1;
  
  // Pipeline stage 2: Acknowledgment Processing
  reg in_ack_slot_stage2, in_ack_delim_stage2;
  reg can_rx_stage2, can_tx_stage2;
  reg valid_stage2;
  
  // Pipeline stage 3: Error Detection
  reg ack_error_stage3, can_ack_drive_stage3;
  reg valid_stage3;
  
  // Pipeline stage 1: Input Registration
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      in_ack_slot_stage1 <= 1'b0;
      in_ack_delim_stage1 <= 1'b0;
      can_rx_stage1 <= 1'b0;
      can_tx_stage1 <= 1'b0;
      valid_stage1 <= 1'b0;
    end else begin
      // Register inputs
      in_ack_slot_stage1 <= in_ack_slot;
      in_ack_delim_stage1 <= in_ack_delim;
      can_rx_stage1 <= can_rx;
      can_tx_stage1 <= can_tx;
      valid_stage1 <= 1'b1; // Data is valid after reset
    end
  end
  
  // Pipeline stage 2: Acknowledgment Processing
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      in_ack_slot_stage2 <= 1'b0;
      in_ack_delim_stage2 <= 1'b0;
      can_rx_stage2 <= 1'b0;
      can_tx_stage2 <= 1'b0;
      valid_stage2 <= 1'b0;
    end else if (valid_stage1) begin
      // Pass through registered signals
      in_ack_slot_stage2 <= in_ack_slot_stage1;
      in_ack_delim_stage2 <= in_ack_delim_stage1;
      can_rx_stage2 <= can_rx_stage1;
      can_tx_stage2 <= can_tx_stage1;
      valid_stage2 <= valid_stage1;
    end
  end
  
  // Pipeline stage 3: Error Detection and Control Logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ack_error_stage3 <= 1'b0;
      can_ack_drive_stage3 <= 1'b0;
      valid_stage3 <= 1'b0;
    end else if (valid_stage2) begin
      // ACK drive logic (for receiving)
      can_ack_drive_stage3 <= in_ack_slot_stage2 && !can_tx_stage2;
      
      // ACK error logic (for transmitting)
      if (in_ack_slot_stage2 && can_tx_stage2 && can_rx_stage2) begin
        ack_error_stage3 <= 1'b1;  // No acknowledgment received
      end else if (in_ack_delim_stage2) begin
        ack_error_stage3 <= 1'b0;  // Reset for next frame
      end else begin
        ack_error_stage3 <= ack_error; // Hold previous value
      end
      
      valid_stage3 <= valid_stage2;
    end
  end
  
  // Final Output Stage
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ack_error <= 1'b0;
      can_ack_drive <= 1'b0;
    end else if (valid_stage3) begin
      ack_error <= ack_error_stage3;
      can_ack_drive <= can_ack_drive_stage3;
    end
  end
endmodule