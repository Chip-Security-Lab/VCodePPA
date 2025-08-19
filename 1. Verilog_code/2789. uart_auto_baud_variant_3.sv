//SystemVerilog
module uart_auto_baud (
  input wire clk, reset_n,
  input wire rx,
  output reg [7:0] rx_data,
  output reg rx_valid,
  output reg [15:0] detected_baud
);
  // Auto-baud detection states
  localparam AB_IDLE = 2'b00, AB_START = 2'b01, AB_MEASURE = 2'b10, AB_LOCK = 2'b11;
  // UART receive states
  localparam RX_IDLE = 2'b00, RX_START = 2'b01, RX_DATA = 2'b10, RX_STOP = 2'b11;
  
  // Stage 1: Input synchronization and edge detection
  reg [1:0] rx_sync_stage1;  // Synchronization registers for rx
  reg [1:0] rx_sync_stage2;  // Additional sync stage
  wire rx_edge_stage1;       // Edge detection signal stage 1
  reg rx_edge_stage2;        // Edge detection signal stage 2
  
  // Stage 2: State tracking and counters
  reg [1:0] ab_state_stage1;   // Auto-baud state stage 1
  reg [1:0] ab_state_stage2;   // Auto-baud state stage 2
  reg [1:0] rx_state_stage1;   // Receiver state stage 1
  reg [1:0] rx_state_stage2;   // Receiver state stage 2
  
  // Stage 3: Counters and timers with pipeline stages
  reg [15:0] clk_counter_stage1;  // Clock counter for edge timing stage 1
  reg [15:0] clk_counter_stage2;  // Clock counter for edge timing stage 2
  reg [15:0] clk_counter_stage3;  // Clock counter for edge timing stage 3
  reg [15:0] baud_period_stage1;  // Measured baud period stage 1
  reg [15:0] baud_period_stage2;  // Measured baud period stage 2
  reg [15:0] baud_period_stage3;  // Measured baud period stage 3
  reg [15:0] bit_timer_stage1;    // Bit timing counter stage 1
  reg [15:0] bit_timer_stage2;    // Bit timing counter stage 2
  reg [15:0] bit_timer_stage3;    // Bit timing counter stage 3
  reg [2:0] bit_counter_stage1;   // Bit position counter stage 1
  reg [2:0] bit_counter_stage2;   // Bit position counter stage 2
  
  // Stage 4: Data processing pipeline
  reg [7:0] rx_data_stage1;     // Received data stage 1
  reg [7:0] rx_data_stage2;     // Received data stage 2
  reg rx_valid_stage1;          // Valid signal stage 1
  
  // Stage 5: Comparison and calculation results
  reg baud_compare_result_stage1; // Comparison result stage 1
  reg baud_compare_result_stage2; // Comparison result stage 2
  reg bit_timer_expired_stage1;   // Timer expired flag stage 1
  reg bit_timer_expired_stage2;   // Timer expired flag stage 2
  
  // Division pipeline for baud rate calculation
  reg [15:0] division_numerator_stage1;  // Division numerator stage 1
  reg [15:0] division_numerator_stage2;  // Division numerator stage 2
  reg [15:0] division_numerator_stage3;  // Division numerator stage 3
  reg [15:0] division_denominator_stage1; // Division denominator stage 1
  reg [15:0] division_denominator_stage2; // Division denominator stage 2
  reg [15:0] division_result_stage1;     // Division result stage 1
  
  // Stage 1: Three-stage synchronizer for rx input
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      rx_sync_stage1 <= 2'b11;
      rx_sync_stage2 <= 2'b11;
    end else begin
      rx_sync_stage1 <= {rx_sync_stage1[0], rx};
      rx_sync_stage2 <= rx_sync_stage1;
    end
  end
  
  // Edge detection pipeline
  assign rx_edge_stage1 = rx_sync_stage1[1] ^ rx_sync_stage1[0];
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n)
      rx_edge_stage2 <= 1'b0;
    else
      rx_edge_stage2 <= rx_edge_stage1;
  end
  
  // Auto-baud detection state machine with increased pipeline stages
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      ab_state_stage1 <= AB_IDLE;
      ab_state_stage2 <= AB_IDLE;
      clk_counter_stage1 <= 16'h0;
      clk_counter_stage2 <= 16'h0;
      clk_counter_stage3 <= 16'h0;
      baud_period_stage1 <= 16'h0;
      baud_period_stage2 <= 16'h0;
      baud_period_stage3 <= 16'h0;
      detected_baud <= 16'h0;
      baud_compare_result_stage1 <= 1'b0;
      baud_compare_result_stage2 <= 1'b0;
    end else begin
      // Pipeline stage 1 - counter logic and state update
      if (ab_state_stage1 == AB_START || ab_state_stage1 == AB_MEASURE)
        clk_counter_stage1 <= clk_counter_stage1 + 16'h1;

      // Pipeline registers for counters
      clk_counter_stage2 <= clk_counter_stage1;
      clk_counter_stage3 <= clk_counter_stage2;
      baud_period_stage2 <= baud_period_stage1;
      baud_period_stage3 <= baud_period_stage2;
      ab_state_stage2 <= ab_state_stage1;
      
      // Pipeline stage 2 - comparison computation
      baud_compare_result_stage1 <= (clk_counter_stage2 >= {1'b0, baud_period_stage2[15:1]});
      baud_compare_result_stage2 <= baud_compare_result_stage1;
      
      // Pipeline division calculation for baud rate
      if (ab_state_stage2 == AB_MEASURE && rx_edge_stage2 && baud_compare_result_stage2) begin
        division_numerator_stage1 <= 16'd50_000_000;
        division_denominator_stage1 <= baud_period_stage3;
      end
      
      division_numerator_stage2 <= division_numerator_stage1;
      division_numerator_stage3 <= division_numerator_stage2;
      division_denominator_stage2 <= division_denominator_stage1;
      
      // Simplified pipelined division calculation
      if (division_denominator_stage2 != 16'h0)
        division_result_stage1 <= division_numerator_stage3 / division_denominator_stage2;
        
      // Pipeline stage 3 - state machine execution with pipelined inputs
      case (ab_state_stage1)
        AB_IDLE: begin
          if (rx_sync_stage2 == 2'b10) begin // Falling edge (start of start bit)
            ab_state_stage1 <= AB_START;
            clk_counter_stage1 <= 16'h0;
          end
        end
        
        AB_START: begin
          if (rx_sync_stage2 == 2'b01) begin // Rising edge 
            ab_state_stage1 <= AB_MEASURE;
            baud_period_stage1 <= clk_counter_stage3;
            clk_counter_stage1 <= 16'h0;
          end
        end
        
        AB_MEASURE: begin
          if (rx_edge_stage2) begin // Any edge detected
            if (baud_compare_result_stage2) begin
              ab_state_stage1 <= AB_LOCK;
              detected_baud <= division_result_stage1;
            end
            clk_counter_stage1 <= 16'h0;
          end
        end
        
        AB_LOCK: begin
          // Auto-baud locked, no further adjustments
        end
      endcase
    end
  end
  
  // UART receiver with pipelined architecture
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      rx_state_stage1 <= RX_IDLE;
      rx_state_stage2 <= RX_IDLE;
      bit_timer_stage1 <= 16'h0;
      bit_timer_stage2 <= 16'h0;
      bit_timer_stage3 <= 16'h0;
      bit_counter_stage1 <= 3'h0;
      bit_counter_stage2 <= 3'h0;
      rx_data_stage1 <= 8'h0;
      rx_data_stage2 <= 8'h0;
      rx_data <= 8'h0;
      rx_valid_stage1 <= 1'b0;
      rx_valid <= 1'b0;
      bit_timer_expired_stage1 <= 1'b0;
      bit_timer_expired_stage2 <= 1'b0;
    end else if (ab_state_stage2 == AB_LOCK) begin
      // Pipeline registers for state and counters
      rx_state_stage2 <= rx_state_stage1;
      bit_timer_stage2 <= bit_timer_stage1;
      bit_timer_stage3 <= bit_timer_stage2;
      bit_counter_stage2 <= bit_counter_stage1;
      rx_data_stage2 <= rx_data_stage1;
      rx_data <= rx_data_stage2;
      rx_valid <= rx_valid_stage1;

      // Stage 1: Timer increment and comparison calculation
      if ((rx_state_stage1 != RX_IDLE) || (rx_state_stage1 == RX_IDLE && rx_sync_stage2[0] == 1'b0))
        bit_timer_stage1 <= bit_timer_stage1 + 16'h1;
      
      // Pipelined timer comparison
      bit_timer_expired_stage1 <= (bit_timer_stage2 >= baud_period_stage3);
      bit_timer_expired_stage2 <= bit_timer_expired_stage1;
      
      // Stage 2: State machine with pipelined comparisons
      case (rx_state_stage1)
        RX_IDLE: begin
          rx_valid_stage1 <= 1'b0;
          if (rx_sync_stage2[0] == 1'b0) begin // Start bit
            rx_state_stage1 <= RX_START;
            bit_timer_stage1 <= 16'h0;
          end
        end
        
        RX_START: begin
          if (bit_timer_stage3 >= {1'b0, baud_period_stage3[15:1]}) begin // Half baud period
            rx_state_stage1 <= RX_DATA;
            bit_timer_stage1 <= 16'h0;
            bit_counter_stage1 <= 3'h0;
          end
        end
        
        RX_DATA: begin
          if (bit_timer_expired_stage2) begin
            bit_timer_stage1 <= 16'h0;
            rx_data_stage1 <= {rx_sync_stage2[0], rx_data_stage2[7:1]}; // Use synchronized rx
            
            // Optimized bit counter check with pipeline
            if (bit_counter_stage2 == 3'h7)
              rx_state_stage1 <= RX_STOP;
            else
              bit_counter_stage1 <= bit_counter_stage2 + 3'h1;
          end
        end
        
        RX_STOP: begin
          if (bit_timer_expired_stage2) begin
            rx_valid_stage1 <= rx_sync_stage2[0]; // Valid only if stop bit is 1
            rx_state_stage1 <= RX_IDLE;
            bit_timer_stage1 <= 16'h0;
          end
        end
      endcase
    end
  end
endmodule