//SystemVerilog
module state_machine_reset(
  input clk, rst_n, input_bit,
  output reg valid_sequence
);
  localparam S0 = 2'b00, S1 = 2'b01, S2 = 2'b10, S3 = 2'b11;
  
  // State registers
  reg [1:0] state, next_state;
  
  // Pipeline stage registers
  reg valid_sequence_internal;
  reg stage_valid;
  
  // Input bit is directly used in combinational logic without first stage register
  
  // State update and next state computation
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= S0;
      stage_valid <= 1'b0;
    end
    else begin
      state <= next_state;
      stage_valid <= 1'b1;
    end
  end
  
  // Next state computation - moved before register
  always @(*) begin
    case (state)
      S0: next_state = input_bit ? S1 : S0;
      S1: next_state = input_bit ? S1 : S2;
      S2: next_state = input_bit ? S3 : S0;
      S3: next_state = input_bit ? S1 : S2;
    endcase
  end
  
  // Valid sequence detection
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      valid_sequence_internal <= 1'b0;
    end
    else begin
      valid_sequence_internal <= (state == S3);
    end
  end
  
  // Output stage
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      valid_sequence <= 1'b0;
    end
    else if (stage_valid) begin
      valid_sequence <= valid_sequence_internal;
    end
  end
endmodule