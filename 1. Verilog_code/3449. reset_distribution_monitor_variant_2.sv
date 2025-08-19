//SystemVerilog
module reset_distribution_monitor (
  input wire clk,
  input wire global_reset,
  input wire [7:0] local_resets,
  output reg distribution_error
);
  reg global_reset_d;
  reg [2:0] check_state;
  wire [2:0] next_state;
  
  // Parallel Prefix Adder implementation for 3-bit addition
  wire [2:0] p, g; // Propagate and Generate signals
  wire [2:0] c;    // Carry signals
  
  // First stage: Generate propagate and generate signals
  assign p[0] = check_state[0];
  assign p[1] = check_state[1];
  assign p[2] = check_state[2];
  
  assign g[0] = 1'b0; // For incrementing by 1, g[0] is always 0
  assign g[1] = check_state[0];
  assign g[2] = check_state[1] & check_state[0];
  
  // Second stage: Generate carry signals
  assign c[0] = 1'b1; // Carry-in for increment by 1
  assign c[1] = g[0] | (p[0] & c[0]);
  assign c[2] = g[1] | (p[1] & (g[0] | (p[0] & c[0])));
  
  // Final stage: Generate sum
  assign next_state[0] = p[0] ^ c[0];
  assign next_state[1] = p[1] ^ c[1];
  assign next_state[2] = p[2] ^ c[2];
  
  always @(posedge clk) begin
    global_reset_d <= global_reset;
    
    case ({global_reset && !global_reset_d, check_state})
      {1'b1, 3'b???}: begin
        check_state <= 3'd0;
        distribution_error <= 1'b0;
      end
      {1'b0, 3'b011}: begin
        check_state <= next_state;
        if (local_resets != 8'hFF)
          distribution_error <= 1'b1;
      end
      {1'b0, 3'b000},
      {1'b0, 3'b001},
      {1'b0, 3'b010}: begin
        check_state <= next_state;
      end
      default: begin
        // 保持状态不变
      end
    endcase
  end
endmodule