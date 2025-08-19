//SystemVerilog
module moore_3state_seq #(parameter WIDTH = 4)(
  input  clk,
  input  rst,
  output reg [WIDTH-1:0] seq_out
);
  
  // Using one-hot encoding for better timing
  reg [2:0] state, next_state;
  localparam S0 = 3'b001,
             S1 = 3'b010,
             S2 = 3'b100;
             
  // Pre-compute the repeating pattern values
  reg [WIDTH-1:0] s2_pattern;
  
  // Initialize pattern registers
  initial begin
    s2_pattern = {{(WIDTH/2){2'b10}}, {(WIDTH%2){1'b0}}};
  end

  // Sequential logic block - unchanged functionality
  always @(posedge clk or posedge rst) begin
    if (rst) 
      state <= S0;
    else     
      state <= next_state;
  end

  // Next state logic - simplified with one-hot encoding
  always @(*) begin
    case (1'b1) // Case based on one-hot bit position
      state[0]: next_state = S1;
      state[1]: next_state = S2;
      state[2]: next_state = S0;
      default:  next_state = S0; // Safe default
    endcase
  end

  // Output logic - pre-computed values for faster path
  always @(*) begin
    case (1'b1) // Case based on one-hot bit position
      state[0]: seq_out = {WIDTH{1'b0}};
      state[1]: seq_out = {WIDTH{1'b1}};
      state[2]: seq_out = s2_pattern;
      default:  seq_out = {WIDTH{1'b0}}; // Safe default
    endcase
  end
  
endmodule