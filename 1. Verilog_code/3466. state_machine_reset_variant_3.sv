//SystemVerilog
module state_machine_reset(
  input clk, rst_n, input_bit,
  output reg valid_sequence,
  input [1:0] multiplicand, multiplier,
  output reg [3:0] product
);
  localparam S0 = 2'b00, S1 = 2'b01, S2 = 2'b10, S3 = 2'b11;
  reg [1:0] state, next_state;
  reg input_bit_pipe;
  reg valid_sequence_comb;
  
  // Booth multiplier signals
  reg [3:0] booth_product;
  reg [2:0] booth_multiplier; // includes extra bit for Booth algorithm
  reg [3:0] partial_product;
  reg [1:0] booth_step;
  
  // Pipeline input signal
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      input_bit_pipe <= 1'b0;
    end
    else begin
      input_bit_pipe <= input_bit;
    end
  end
  
  // State register
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= S0;
    end
    else begin
      state <= next_state;
    end
  end
  
  // Next state logic
  always @(*) begin
    case (state)
      S0: begin
        if (input_bit_pipe) begin
          next_state = S1;
        end
        else begin
          next_state = S0;
        end
      end
      
      S1: begin
        if (input_bit_pipe) begin
          next_state = S1;
        end
        else begin
          next_state = S2;
        end
      end
      
      S2: begin
        if (input_bit_pipe) begin
          next_state = S3;
        end
        else begin
          next_state = S0;
        end
      end
      
      S3: begin
        if (input_bit_pipe) begin
          next_state = S1;
        end
        else begin
          next_state = S2;
        end
      end
      
      default: begin
        next_state = S0;
      end
    endcase
  end
  
  // Output logic
  always @(*) begin
    if (state == S3) begin
      valid_sequence_comb = 1'b1;
    end
    else begin
      valid_sequence_comb = 1'b0;
    end
  end
  
  // Register output for better timing
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      valid_sequence <= 1'b0;
    end
    else begin
      valid_sequence <= valid_sequence_comb;
    end
  end
  
  // 2-bit Booth multiplier implementation
  always @(*) begin
    // Initialize booth multiplier with extra '0' bit at LSB for Booth algorithm
    booth_multiplier = {multiplier, 1'b0};
    booth_product = 4'b0000;
    
    // First Booth step
    if (booth_multiplier[1:0] == 2'b01) begin
      booth_product = {{2{multiplicand[1]}}, multiplicand}; // +M
    end
    else if (booth_multiplier[1:0] == 2'b10) begin
      booth_product = ~({{2{multiplicand[1]}}, multiplicand}) + 1'b1; // -M
    end
    else begin
      booth_product = 4'b0000; // 00 or 11: add 0
    end
    
    // Second Booth step (shifted)
    partial_product = 4'b0000;
    if (booth_multiplier[2:1] == 2'b01) begin
      partial_product = {{2{multiplicand[1]}}, multiplicand}; // +M
    end
    else if (booth_multiplier[2:1] == 2'b10) begin
      partial_product = ~({{2{multiplicand[1]}}, multiplicand}) + 1'b1; // -M
    end
    else begin
      partial_product = 4'b0000; // 00 or 11: add 0
    end
    
    // Combine results
    booth_product = booth_product + (partial_product << 1);
  end
  
  // Register the multiplication result
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      product <= 4'b0000;
    end
    else begin
      product <= booth_product;
    end
  end
  
endmodule