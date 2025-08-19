//SystemVerilog
// Module for calculating parity bits of a 16-bit data word with req-ack handshake
module multi_bit_parity(
  input        clk,
  input        rst_n,
  input        req_in,      // Request signal (replaces valid)
  input [15:0] data_word,
  output       ack_in,      // Acknowledge signal (replaces ready)
  output       req_out,     // Request output signal
  output [1:0] parity_bits,
  input        ack_out      // Acknowledge input signal
);

  // Internal signals
  reg req_in_reg, req_out_reg;
  reg [15:0] data_word_reg;
  reg [1:0] parity_bits_reg;
  
  // Handshake control FSM states
  localparam IDLE = 2'b00;
  localparam PROCESSING = 2'b01;
  localparam WAITING_ACK = 2'b10;
  
  reg [1:0] current_state, next_state;
  
  // Submodule connections
  wire lower_parity, upper_parity;
  
  // State machine sequential logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      current_state <= IDLE;
      data_word_reg <= 16'b0;
      req_in_reg <= 1'b0;
      req_out_reg <= 1'b0;
      parity_bits_reg <= 2'b0;
    end else begin
      current_state <= next_state;
      
      // Register input data when handshake occurs
      if (current_state == IDLE && req_in && ack_in) begin
        data_word_reg <= data_word;
        req_in_reg <= 1'b1;
      end else if (current_state == PROCESSING) begin
        req_in_reg <= 1'b0;
        parity_bits_reg <= {upper_parity, lower_parity};
        req_out_reg <= 1'b1;
      end else if (current_state == WAITING_ACK && ack_out) begin
        req_out_reg <= 1'b0;
      end
    end
  end
  
  // State machine combinational logic
  always @(*) begin
    case (current_state)
      IDLE: 
        next_state = (req_in && ack_in) ? PROCESSING : IDLE;
      PROCESSING: 
        next_state = WAITING_ACK;
      WAITING_ACK: 
        next_state = (ack_out) ? IDLE : WAITING_ACK;
      default: 
        next_state = IDLE;
    endcase
  end
  
  // Submodule for calculating the parity of the lower 8 bits
  parity_calculator lower_parity_unit (
    .data(data_word_reg[7:0]),
    .parity(lower_parity)
  );

  // Submodule for calculating the parity of the upper 8 bits
  parity_calculator upper_parity_unit (
    .data(data_word_reg[15:8]),
    .parity(upper_parity)
  );
  
  // Output assignments
  assign ack_in = (current_state == IDLE);
  assign req_out = req_out_reg;
  assign parity_bits = parity_bits_reg;

endmodule

// Submodule for parity calculation
module parity_calculator(
  input [7:0] data,
  output parity
);
  assign parity = ^data; // Calculate parity using XOR reduction
endmodule