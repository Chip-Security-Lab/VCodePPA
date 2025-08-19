//SystemVerilog
//IEEE 1364-2005 Verilog Standard
module can_state_machine(
  input wire clk, rst_n,
  input wire rx_start, tx_request,
  input wire bit_time, error_detected,
  output reg tx_active, rx_active,
  output reg [9:0] state
);
  // One-hot encoded state definitions
  localparam [9:0] IDLE       = 10'b0000000001,
                   SOF        = 10'b0000000010,
                   ARBITRATION= 10'b0000000100,
                   CONTROL    = 10'b0000001000,
                   DATA       = 10'b0000010000,
                   CRC        = 10'b0000100000,
                   ACK        = 10'b0001000000,
                   EOF        = 10'b0010000000,
                   IFS        = 10'b0100000000,
                   ERROR      = 10'b1000000000;
                   
  reg [9:0] next_state_stage1, next_state_stage2, next_state_stage3;
  reg [7:0] bit_counter, bit_counter_stage1, bit_counter_stage2;
  reg error_detected_stage1, error_detected_stage2;
  reg bit_time_stage1, bit_time_stage2;
  reg tx_request_stage1, rx_start_stage1;
  reg [9:0] state_stage1, state_stage2;
  
  // Stage 1: Input Registration
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      error_detected_stage1 <= 0;
      bit_time_stage1 <= 0;
      tx_request_stage1 <= 0;
      rx_start_stage1 <= 0;
      state_stage1 <= IDLE;
    end else begin
      error_detected_stage1 <= error_detected;
      bit_time_stage1 <= bit_time;
      tx_request_stage1 <= tx_request;
      rx_start_stage1 <= rx_start;
      state_stage1 <= state;
    end
  end
  
  // Stage 2: Next State Logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      next_state_stage1 <= IDLE;
      error_detected_stage2 <= 0;
      bit_time_stage2 <= 0;
      state_stage2 <= IDLE;
    end else begin
      case(state_stage1)
        IDLE: next_state_stage1 <= tx_request_stage1 ? SOF : (rx_start_stage1 ? SOF : IDLE);
        SOF: next_state_stage1 <= ARBITRATION;
        ARBITRATION: next_state_stage1 <= (bit_counter_stage1 >= 11) ? CONTROL : ARBITRATION;
        CONTROL: next_state_stage1 <= (bit_counter_stage1 >= 12) ? DATA : CONTROL;
        DATA: next_state_stage1 <= (bit_counter_stage1 >= 64) ? CRC : DATA;
        CRC: next_state_stage1 <= (bit_counter_stage1 >= 15) ? ACK : CRC;
        ACK: next_state_stage1 <= (bit_counter_stage1 >= 2) ? EOF : ACK;
        EOF: next_state_stage1 <= (bit_counter_stage1 >= 7) ? IFS : EOF;
        IFS: next_state_stage1 <= (bit_counter_stage1 >= 3) ? IDLE : IFS;
        ERROR: next_state_stage1 <= (bit_counter_stage1 >= 6) ? IDLE : ERROR;
        default: next_state_stage1 <= IDLE;
      endcase
      
      error_detected_stage2 <= error_detected_stage1;
      bit_time_stage2 <= bit_time_stage1;
      state_stage2 <= state_stage1;
    end
  end
  
  // Stage 3: Bit Counter Logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      bit_counter_stage1 <= 0;
      next_state_stage2 <= IDLE;
    end else begin
      if (state_stage1 != next_state_stage1 && bit_time_stage1)
        bit_counter_stage1 <= 0;
      else if (bit_time_stage1)
        bit_counter_stage1 <= bit_counter_stage1 + 1;
      
      next_state_stage2 <= next_state_stage1;
    end
  end
  
  // Stage 4: Final State Update and Output Logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
      tx_active <= 0;
      rx_active <= 0;
      bit_counter <= 0;
      next_state_stage3 <= IDLE;
    end else begin
      next_state_stage3 <= error_detected_stage2 ? ERROR : next_state_stage2;
      
      if (bit_time_stage2) begin
        state <= next_state_stage3;
        bit_counter <= (state_stage2 != next_state_stage3) ? 0 : bit_counter + 1;
        
        // Set outputs based on state
        case(next_state_stage3)
          IDLE: begin
            tx_active <= 0;
            rx_active <= 0;
          end
          SOF: begin
            tx_active <= tx_request_stage1;
            rx_active <= rx_start_stage1;
          end
          ARBITRATION, CONTROL, DATA, CRC, ACK, EOF: begin
            tx_active <= (state_stage2 == IDLE) ? tx_request_stage1 : tx_active;
            rx_active <= (state_stage2 == IDLE) ? rx_start_stage1 : rx_active;
          end
          ERROR: begin
            tx_active <= 0;
            rx_active <= 0;
          end
          default: begin
            tx_active <= tx_active;
            rx_active <= rx_active;
          end
        endcase
      end
    end
  end
endmodule