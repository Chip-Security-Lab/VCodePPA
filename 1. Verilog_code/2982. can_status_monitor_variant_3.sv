//SystemVerilog - IEEE 1364-2005
module can_status_monitor(
  input wire clk, rst_n,
  input wire tx_active, rx_active,
  input wire error_detected, bus_off,
  input wire [7:0] tx_err_count, rx_err_count,
  output reg [2:0] node_state,
  output reg [15:0] frames_sent, frames_received,
  output reg [15:0] errors_detected
);
  localparam [2:0] ERROR_ACTIVE = 3'd0, 
                   ERROR_PASSIVE = 3'd1, 
                   BUS_OFF = 3'd2;
  
  // Stage 1: Edge detection and initial processing
  reg prev_tx_active_stage1, prev_rx_active_stage1, prev_error_stage1;
  wire tx_edge_stage1, rx_edge_stage1, error_edge_stage1;
  reg err_passive_condition_stage1;
  reg [1:0] state_decision_stage1;
  reg bus_off_stage1;
  
  // Stage 2: Counter updates and state determination
  reg tx_edge_stage2, rx_edge_stage2, error_edge_stage2;
  reg [1:0] state_decision_stage2;
  reg [15:0] frames_sent_stage2, frames_received_stage2, errors_detected_stage2;
  reg [2:0] node_state_stage2;
  
  // Pipeline valid signals
  reg stage1_valid, stage2_valid;
  
  // Stage 1 Logic: Edge detection and comparator logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // Reset stage 1 registers
      prev_tx_active_stage1 <= 1'b0;
      prev_rx_active_stage1 <= 1'b0;
      prev_error_stage1 <= 1'b0;
      err_passive_condition_stage1 <= 1'b0;
      state_decision_stage1 <= 2'b00;
      bus_off_stage1 <= 1'b0;
      stage1_valid <= 1'b0;
    end else begin
      // Edge detection logic
      prev_tx_active_stage1 <= tx_active;
      prev_rx_active_stage1 <= rx_active;
      prev_error_stage1 <= error_detected;
      
      // Calculate edge signals
      tx_edge_stage2 <= !prev_tx_active_stage1 && tx_active;
      rx_edge_stage2 <= !prev_rx_active_stage1 && rx_active;
      error_edge_stage2 <= !prev_error_stage1 && error_detected;
      
      // Error condition determination
      err_passive_condition_stage1 <= tx_err_count[7] | (tx_err_count[6:0] > 7'h7F) | 
                                     rx_err_count[7] | (rx_err_count[6:0] > 7'h7F);
      
      // State decision encoding
      state_decision_stage2 <= {bus_off, err_passive_condition_stage1};
      
      // Pipeline control
      stage1_valid <= 1'b1;
    end
  end
  
  // Stage 2 Logic: Counter updates and state determination
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // Reset stage 2 registers
      frames_sent <= 16'h0;
      frames_received <= 16'h0;
      errors_detected <= 16'h0;
      node_state <= ERROR_ACTIVE;
      stage2_valid <= 1'b0;
    end else if (stage1_valid) begin
      // Counter logic with edge detection
      if (tx_edge_stage2) 
        frames_sent <= frames_sent + 16'h1;
      
      if (rx_edge_stage2)
        frames_received <= frames_received + 16'h1;
      
      if (error_edge_stage2)
        errors_detected <= errors_detected + 16'h1;
      
      // Converted state machine using if-else cascade instead of case
      if (state_decision_stage2[1] == 1'b1) begin
        // 2'b10 or 2'b11: Bus off takes precedence
        node_state <= BUS_OFF;
      end else if (state_decision_stage2 == 2'b01) begin
        // Error passive condition
        node_state <= ERROR_PASSIVE;
      end else begin
        // 2'b00: Default state and safety default
        node_state <= ERROR_ACTIVE;
      end
      
      // Pipeline control
      stage2_valid <= stage1_valid;
    end
  end
endmodule