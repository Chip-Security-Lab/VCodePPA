//SystemVerilog
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
  
  // Pipeline stage 1 - Edge detection registers
  reg prev_tx_active_stage1, prev_rx_active_stage1, prev_error_stage1;
  reg tx_active_stage1, rx_active_stage1, error_detected_stage1;
  reg bus_off_stage1;
  reg [7:0] tx_err_count_stage1, rx_err_count_stage1;
  reg valid_stage1;
  
  // Pipeline stage 2 - Edge calculation
  reg tx_frame_edge_stage2, rx_frame_edge_stage2, error_edge_stage2;
  reg bus_off_stage2;
  reg [7:0] tx_err_count_stage2, rx_err_count_stage2;
  reg valid_stage2;
  
  // Pipeline stage 3 - State calculation
  reg [1:0] state_calc_stage3;
  reg tx_frame_edge_stage3, rx_frame_edge_stage3, error_edge_stage3;
  reg valid_stage3;
  
  // Stage 1: Input Registration and Synchronization
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // Reset stage 1 registers
      prev_tx_active_stage1 <= 1'b0;
      prev_rx_active_stage1 <= 1'b0;
      prev_error_stage1 <= 1'b0;
      tx_active_stage1 <= 1'b0;
      rx_active_stage1 <= 1'b0;
      error_detected_stage1 <= 1'b0;
      bus_off_stage1 <= 1'b0;
      tx_err_count_stage1 <= 8'h0;
      rx_err_count_stage1 <= 8'h0;
      valid_stage1 <= 1'b0;
    end else begin
      // Register all inputs
      prev_tx_active_stage1 <= tx_active;
      prev_rx_active_stage1 <= rx_active;
      prev_error_stage1 <= error_detected;
      tx_active_stage1 <= tx_active;
      rx_active_stage1 <= rx_active;
      error_detected_stage1 <= error_detected;
      bus_off_stage1 <= bus_off;
      tx_err_count_stage1 <= tx_err_count;
      rx_err_count_stage1 <= rx_err_count;
      valid_stage1 <= 1'b1;
    end
  end
  
  // Stage 2: Edge Detection
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // Reset stage 2 registers
      tx_frame_edge_stage2 <= 1'b0;
      rx_frame_edge_stage2 <= 1'b0;
      error_edge_stage2 <= 1'b0;
      bus_off_stage2 <= 1'b0;
      tx_err_count_stage2 <= 8'h0;
      rx_err_count_stage2 <= 8'h0;
      valid_stage2 <= 1'b0;
    end else begin
      // Calculate edges and propagate data
      tx_frame_edge_stage2 <= valid_stage1 & !prev_tx_active_stage1 & tx_active_stage1;
      rx_frame_edge_stage2 <= valid_stage1 & !prev_rx_active_stage1 & rx_active_stage1;
      error_edge_stage2 <= valid_stage1 & !prev_error_stage1 & error_detected_stage1;
      bus_off_stage2 <= bus_off_stage1;
      tx_err_count_stage2 <= tx_err_count_stage1;
      rx_err_count_stage2 <= rx_err_count_stage1;
      valid_stage2 <= valid_stage1;
    end
  end
  
  // Stage 3: State Calculation
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // Reset stage 3 registers
      state_calc_stage3 <= ERROR_ACTIVE;
      tx_frame_edge_stage3 <= 1'b0;
      rx_frame_edge_stage3 <= 1'b0;
      error_edge_stage3 <= 1'b0;
      valid_stage3 <= 1'b0;
    end else begin
      // Calculate state and propagate edge signals
      state_calc_stage3 <= valid_stage2 ? (
                           bus_off_stage2 ? BUS_OFF : 
                           ((|tx_err_count_stage2[7:7]) || (|rx_err_count_stage2[7:7])) ? ERROR_PASSIVE : 
                           ERROR_ACTIVE) : state_calc_stage3;
      tx_frame_edge_stage3 <= tx_frame_edge_stage2;
      rx_frame_edge_stage3 <= rx_frame_edge_stage2;
      error_edge_stage3 <= error_edge_stage2;
      valid_stage3 <= valid_stage2;
    end
  end
  
  // Final stage: Counter and State Updates
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      node_state <= ERROR_ACTIVE;
      frames_sent <= 16'h0;
      frames_received <= 16'h0;
      errors_detected <= 16'h0;
    end else if (valid_stage3) begin
      // Update counters based on edge signals
      frames_sent <= frames_sent + {15'h0, tx_frame_edge_stage3};
      frames_received <= frames_received + {15'h0, rx_frame_edge_stage3};
      errors_detected <= errors_detected + {15'h0, error_edge_stage3};
      
      // Update state
      node_state <= state_calc_stage3;
    end
  end
endmodule