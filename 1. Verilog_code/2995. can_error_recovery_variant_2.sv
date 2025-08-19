//SystemVerilog
module can_error_recovery (
  input  wire       clk,
  input  wire       rst_n,
  input  wire       error_detected,
  input  wire       bus_off_state,
  input  wire [7:0] tx_error_count,
  input  wire [7:0] rx_error_count,
  output reg  [1:0] error_state,
  output reg        error_passive_mode,
  output reg        recovery_in_progress
);

  // Constants and parameters
  localparam ERROR_ACTIVE  = 2'b00;
  localparam ERROR_PASSIVE = 2'b01;
  localparam BUS_OFF       = 2'b10;
  
  // Internal registers
  reg [9:0] recovery_counter;
  
  // Pipeline stage 1: Error threshold detection
  reg tx_error_above_255_r;
  reg tx_error_above_128_r;
  reg rx_error_above_128_r;
  reg bus_off_state_r;
  
  // Pipeline stage 2: State computation
  reg [1:0] next_error_state_r;
  reg next_error_passive_mode_r;
  reg recovery_complete_r;
  
  // Pipeline stage 3: Recovery logic
  reg next_recovery_in_progress_r;
  reg [9:0] next_recovery_counter_r;
  
  // ===================================================
  // Pipeline Stage 1: Error threshold comparison
  // ===================================================
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_error_above_255_r <= 1'b0;
      tx_error_above_128_r <= 1'b0;
      rx_error_above_128_r <= 1'b0;
      bus_off_state_r      <= 1'b0;
    end else begin
      tx_error_above_255_r <= (tx_error_count >= 8'd255);
      tx_error_above_128_r <= (tx_error_count >= 8'd128);
      rx_error_above_128_r <= (rx_error_count >= 8'd128);
      bus_off_state_r      <= bus_off_state;
    end
  end
  
  // ===================================================
  // Pipeline Stage 2: State determination
  // ===================================================
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      next_error_state_r       <= ERROR_ACTIVE;
      next_error_passive_mode_r <= 1'b0;
      recovery_complete_r      <= 1'b0;
    end else begin
      // State decision logic
      if (tx_error_above_255_r || bus_off_state_r) begin
        next_error_state_r <= BUS_OFF;
      end else if (tx_error_above_128_r || rx_error_above_128_r) begin
        next_error_state_r <= ERROR_PASSIVE;
      end else begin
        next_error_state_r <= ERROR_ACTIVE;
      end
      
      // Passive mode determination
      next_error_passive_mode_r <= (tx_error_above_255_r || bus_off_state_r) || 
                                  (tx_error_above_128_r || rx_error_above_128_r);
      
      // Recovery completion check
      recovery_complete_r <= (recovery_counter >= 10'd127);
    end
  end
  
  // ===================================================
  // Pipeline Stage 3: Recovery management
  // ===================================================
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      next_recovery_in_progress_r <= 1'b0;
      next_recovery_counter_r     <= 10'd0;
    end else begin
      // Recovery progress logic
      if (tx_error_above_255_r || bus_off_state_r) begin
        next_recovery_in_progress_r <= 1'b1;
      end else if (recovery_in_progress && !recovery_complete_r) begin
        next_recovery_in_progress_r <= 1'b1;
      end else begin
        next_recovery_in_progress_r <= 1'b0;
      end
      
      // Counter management
      if (!recovery_in_progress && (tx_error_above_255_r || bus_off_state_r)) begin
        next_recovery_counter_r <= 10'd1;
      end else if (recovery_in_progress && !recovery_complete_r) begin
        next_recovery_counter_r <= recovery_counter + 10'd1;
      end else begin
        next_recovery_counter_r <= 10'd0;
      end
    end
  end
  
  // ===================================================
  // Output Stage: Update module outputs and counters
  // ===================================================
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      error_state          <= ERROR_ACTIVE;
      error_passive_mode   <= 1'b0;
      recovery_in_progress <= 1'b0;
      recovery_counter     <= 10'd0;
    end else begin
      error_state          <= next_error_state_r;
      error_passive_mode   <= next_error_passive_mode_r;
      recovery_in_progress <= next_recovery_in_progress_r;
      recovery_counter     <= next_recovery_counter_r;
    end
  end

endmodule