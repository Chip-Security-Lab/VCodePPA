//SystemVerilog
module moore_4state_1010_seq_detector(
  input  wire clk,
  input  wire rst,
  input  wire in,
  output wire found
);
  // State encoding with one-hot to improve timing
  localparam [3:0] S0 = 4'b0001,  // Initial state
                   S1 = 4'b0010,  // Detected "1"
                   S2 = 4'b0100,  // Detected "10"
                   S3 = 4'b1000;  // Detected "101"
  
  // State registers - using registered outputs for better timing
  reg [3:0] current_state, next_state;
  reg [3:0] current_state_stage1, next_state_stage1, current_state_stage2, next_state_stage2;
  reg input_reg;         // Register input to improve timing
  reg input_reg_stage1;  // Additional pipeline stage for input
  reg input_reg_stage2;  // Second additional pipeline stage for input
  reg pre_found;         // Pipeline register for output
  reg pre_found_stage1;  // First additional pipeline stage for output
  reg pre_found_stage2;  // Second additional pipeline stage for output

  // Input registration stage
  always @(posedge clk or posedge rst) begin
    if (rst)
      input_reg <= 1'b0;
    else
      input_reg <= in;
  end

  // Additional input pipeline stages
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      input_reg_stage1 <= 1'b0;
      input_reg_stage2 <= 1'b0;
    end else begin
      input_reg_stage1 <= input_reg;
      input_reg_stage2 <= input_reg_stage1;
    end
  end

  // State register update - synchronous reset for better FPGA implementation
  always @(posedge clk) begin
    if (rst)
      current_state <= S0;
    else
      current_state <= next_state_stage2;
  end

  // Additional state pipeline stages
  always @(posedge clk) begin
    if (rst) begin
      current_state_stage1 <= S0;
      current_state_stage2 <= S0;
    end else begin
      current_state_stage1 <= current_state;
      current_state_stage2 <= current_state_stage1;
    end
  end

  // Next state logic - separated from state register update for better timing
  always @(*) begin
    // Default assignment to prevent latches
    next_state = current_state;
    
    case (current_state)
      S0: next_state = input_reg_stage2 ? S1 : S0;
      S1: next_state = input_reg_stage2 ? S1 : S2;
      S2: next_state = input_reg_stage2 ? S3 : S0;
      S3: next_state = input_reg_stage2 ? S1 : S2;
      default: next_state = S0;  // Recovery state for better reliability
    endcase
  end

  // Additional next state pipeline stages
  always @(posedge clk) begin
    if (rst) begin
      next_state_stage1 <= S0;
      next_state_stage2 <= S0;
    end else begin
      next_state_stage1 <= next_state;
      next_state_stage2 <= next_state_stage1;
    end
  end

  // Output logic pipeline - first stage
  always @(posedge clk or posedge rst) begin
    if (rst)
      pre_found <= 1'b0;
    else
      pre_found <= (current_state_stage2 == S3 && input_reg_stage2 == 1'b0);
  end

  // Output logic pipeline - second stage
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      pre_found_stage1 <= 1'b0;
      pre_found_stage2 <= 1'b0;
    end else begin
      pre_found_stage1 <= pre_found;
      pre_found_stage2 <= pre_found_stage1;
    end
  end

  // Final output assignment
  assign found = pre_found_stage2;
  
endmodule