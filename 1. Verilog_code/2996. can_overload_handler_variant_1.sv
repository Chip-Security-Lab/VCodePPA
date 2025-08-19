//SystemVerilog
module can_overload_handler(
  input wire clk, rst_n,
  input wire can_rx, bit_timing,
  input wire frame_end, inter_frame_space,
  output reg overload_detected,
  output reg can_tx_overload
);
  // FSM state definitions - using one-hot encoding for faster state transitions
  localparam [3:0] IDLE      = 4'b0001,
                   DETECT    = 4'b0010, 
                   FLAG      = 4'b0100, 
                   DELIMITER = 4'b1000;
  
  // Pipeline stage registers with one-hot encoding
  reg [3:0] state_stage1, state_stage2;
  
  // Counter registers
  reg [2:0] bit_counter_stage1, bit_counter_stage2; // Reduced from 4 to 3 bits as max count is 7
  
  // Status registers
  reg overload_detected_stage1;
  reg can_tx_overload_stage1;
  
  // Pipeline control signals
  reg valid_stage1, valid_stage2;
  
  // Pre-computed transition conditions to reduce critical path
  wire detect_transition = state_stage1[1] && inter_frame_space && !can_rx;
  wire flag_complete = state_stage1[2] && (bit_counter_stage1 >= 3'd5);
  wire delimiter_complete = state_stage1[3] && (bit_counter_stage1 >= 3'd7);
  wire idle_transition = state_stage1[0] && frame_end;
  
  // Stage 1: State detection and transition logic with balanced paths
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state_stage1 <= IDLE;
      bit_counter_stage1 <= 3'd0;
      overload_detected_stage1 <= 1'b0;
      can_tx_overload_stage1 <= 1'b0;
      valid_stage1 <= 1'b0;
    end else if (bit_timing) begin
      valid_stage1 <= 1'b1;
      
      // Parallel state transition logic
      if (idle_transition)
        state_stage1 <= DETECT;
      else if (detect_transition)
        state_stage1 <= FLAG;
      else if (flag_complete)
        state_stage1 <= DELIMITER;
      else if (delimiter_complete)
        state_stage1 <= IDLE;
        
      // Counter logic separated from state transitions
      if (state_stage1[2] || state_stage1[3]) // FLAG or DELIMITER
        bit_counter_stage1 <= bit_counter_stage1 + 3'd1;
      else if (idle_transition || detect_transition || delimiter_complete)
        bit_counter_stage1 <= 3'd0;
        
      // Overload detection logic
      if (detect_transition)
        overload_detected_stage1 <= 1'b1;
      else if (delimiter_complete)
        overload_detected_stage1 <= 1'b0;
        
      // TX control logic
      if (state_stage1[2] || (detect_transition)) // FLAG or entering FLAG
        can_tx_overload_stage1 <= 1'b1;
      else if (flag_complete || state_stage1[3]) // DELIMITER or entering DELIMITER
        can_tx_overload_stage1 <= 1'b0;
    end else begin
      valid_stage1 <= 1'b0;
    end
  end
  
  // Pipeline registers between Stage 1 and Stage 2
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state_stage2 <= IDLE;
      bit_counter_stage2 <= 3'd0;
      overload_detected <= 1'b0;
      can_tx_overload <= 1'b0;
      valid_stage2 <= 1'b0;
    end else if (bit_timing) begin
      state_stage2 <= state_stage1;
      bit_counter_stage2 <= bit_counter_stage1;
      overload_detected <= overload_detected_stage1;
      can_tx_overload <= can_tx_overload_stage1;
      valid_stage2 <= valid_stage1;
    end
  end
  
endmodule