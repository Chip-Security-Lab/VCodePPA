//SystemVerilog
module reset_event_counter (
  input wire clk,
  input wire reset_n,
  output reg [7:0] reset_count
);
  // Stage 1: Reset detection
  reg reset_detected_stage1;
  always @(posedge clk) begin
    reset_detected_stage1 <= !reset_n;
  end
  
  // Stage 2: Increment preparation
  reg reset_detected_stage2;
  reg [7:0] current_count_stage2;
  always @(posedge clk) begin
    reset_detected_stage2 <= reset_detected_stage1;
    current_count_stage2 <= reset_count;
  end
  
  // Stage 3: Increment calculation using carry-lookahead adder
  reg reset_detected_stage3;
  reg [7:0] next_count_stage3;
  
  // Carry-lookahead adder implementation
  wire [7:0] sum;
  wire [7:0] g; // Generate
  wire [7:0] p; // Propagate
  wire [8:0] c; // Carry (including initial carry-in)
  
  // Generate and propagate signals
  assign g = current_count_stage2 & 8'h01;
  assign p = current_count_stage2 | 8'h01;
  
  // Carry lookahead calculation
  assign c[0] = 1'b0; // Initial carry-in is 0
  assign c[1] = g[0] | (p[0] & c[0]);
  assign c[2] = g[1] | (p[1] & c[1]);
  assign c[3] = g[2] | (p[2] & c[2]);
  assign c[4] = g[3] | (p[3] & c[3]);
  assign c[5] = g[4] | (p[4] & c[4]);
  assign c[6] = g[5] | (p[5] & c[5]);
  assign c[7] = g[6] | (p[6] & c[6]);
  assign c[8] = g[7] | (p[7] & c[7]);
  
  // Sum calculation
  assign sum = current_count_stage2 ^ 8'h01 ^ c[7:0];
  
  always @(posedge clk) begin
    reset_detected_stage3 <= reset_detected_stage2;
    if (reset_detected_stage2)
      next_count_stage3 <= sum;
    else
      next_count_stage3 <= current_count_stage2;
  end
  
  // Final stage: Output update
  always @(posedge clk) begin
    if (reset_detected_stage3)
      reset_count <= next_count_stage3;
  end
endmodule