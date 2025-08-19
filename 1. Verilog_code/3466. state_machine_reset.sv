module state_machine_reset(
  input clk, rst_n, input_bit,
  output reg valid_sequence
);
  localparam S0 = 2'b00, S1 = 2'b01, S2 = 2'b10, S3 = 2'b11;
  reg [1:0] state, next_state;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) state <= S0;
    else state <= next_state;
  end
  
  always @(*) begin
    case (state)
      S0: next_state = input_bit ? S1 : S0;
      S1: next_state = input_bit ? S1 : S2;
      S2: next_state = input_bit ? S3 : S0;
      S3: next_state = input_bit ? S1 : S2;
    endcase
    valid_sequence = (state == S3);
  end
endmodule