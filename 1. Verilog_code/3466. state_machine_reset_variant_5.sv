//SystemVerilog - IEEE 1364-2005
module state_machine_reset(
  input wire clk, rst_n, input_bit,
  input wire ready,           // Added ready input signal
  output reg valid,           // Changed from valid_sequence to valid
  output reg [1:0] data_out   // Added data output to demonstrate data transfer
);
  localparam S0 = 2'b00, S1 = 2'b01, S2 = 2'b10, S3 = 2'b11;
  reg [1:0] state, next_state;
  reg [1:0] state_pipe;
  reg valid_pre;
  reg [1:0] data_out_pre;
  
  // First stage: State transition logic
  always @(*) begin
    case (state)
      S0: next_state = input_bit ? S1 : S0;
      S1: next_state = input_bit ? S1 : S2;
      S2: next_state = input_bit ? S3 : S0;
      S3: next_state = input_bit ? S1 : S2;
      default: next_state = S0;
    endcase
  end
  
  // Second stage: Output logic with pipeline register
  always @(*) begin
    valid_pre = (state_pipe == S3);
    data_out_pre = state_pipe;
  end
  
  // Sequential logic with valid-ready handshake
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= S0;
      state_pipe <= S0;
      valid <= 1'b0;
      data_out <= 2'b00;
    end else begin
      state <= next_state;
      state_pipe <= state;
      
      // Valid-Ready handshake logic
      if (valid && ready) begin
        // Data transfer completed, prepare next data
        valid <= valid_pre;
        data_out <= data_out_pre;
      end else if (!valid) begin
        // No active transfer, can assert valid when new data is available
        valid <= valid_pre;
        data_out <= data_out_pre;
      end
      // When valid=1 but ready=0, hold current valid and data_out (data stall)
    end
  end
endmodule