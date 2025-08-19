//SystemVerilog
module can_state_machine(
  input wire clk, rst_n,
  input wire rx_start, tx_request,
  input wire bit_time, error_detected,
  output reg tx_active, rx_active,
  output reg [3:0] state
);
  localparam IDLE=0, SOF=1, ARBITRATION=2, CONTROL=3, DATA=4, CRC=5, ACK=6, EOF=7, IFS=8, ERROR=9;
  
  // Pre-registered state and control signals
  reg [3:0] next_state;
  reg [7:0] bit_counter;
  reg [7:0] next_bit_counter;
  reg next_tx_active, next_rx_active;
  
  // Registered error detection signal to break long combinational path
  reg error_detected_r;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      error_detected_r <= 1'b0;
    end else begin
      error_detected_r <= error_detected;
    end
  end
  
  // Combinational logic for next state determination
  always @(*) begin
    case(state)
      IDLE: next_state = tx_request ? SOF : (rx_start ? SOF : IDLE);
      SOF: next_state = ARBITRATION;
      ARBITRATION: next_state = CONTROL;
      CONTROL: next_state = DATA;
      DATA: next_state = CRC;
      CRC: next_state = ACK;
      ACK: next_state = EOF;
      EOF: next_state = IFS;
      IFS: next_state = IDLE;
      ERROR: next_state = IDLE;
      default: next_state = IDLE;
    endcase
    
    // Pre-compute bit counter logic
    next_bit_counter = (state != next_state) ? 8'd0 : bit_counter + 8'd1;
    
    // Pre-compute output signals (moved from output registers)
    next_tx_active = (next_state != IDLE && next_state != ERROR && tx_request);
    next_rx_active = (next_state != IDLE && next_state != ERROR && rx_start);
  end
  
  // State and output registers
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
      bit_counter <= 8'd0;
      tx_active <= 1'b0;
      rx_active <= 1'b0;
    end else if (error_detected_r) begin
      state <= ERROR;
      bit_counter <= 8'd0;
      tx_active <= 1'b0;
      rx_active <= 1'b0;
    end else if (bit_time) begin
      state <= next_state;
      bit_counter <= next_bit_counter;
      tx_active <= next_tx_active;
      rx_active <= next_rx_active;
    end
  end
endmodule