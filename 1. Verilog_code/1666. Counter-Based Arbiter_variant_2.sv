//SystemVerilog
module counter_arbiter(
  input wire clock,
  input wire reset,
  input wire [3:0] requests,
  output reg [3:0] grants
);

  // Pipeline stages
  reg [1:0] count_reg;
  reg [1:0] next_count;
  reg [3:0] grant_reg;
  
  // Adder pipeline stages
  reg [3:0] p_reg, g_reg;
  reg [3:0] p1_reg, g1_reg;
  reg [3:0] p2_reg, g2_reg;
  reg [3:0] carry_reg;
  reg [3:0] sum_reg;
  
  // Stage 1: Generate and propagate
  always @(*) begin
    p_reg = {2'b00, count_reg} ^ 4'b0001;
    g_reg = {2'b00, count_reg} & 4'b0001;
  end
  
  // Stage 2: First level prefix computation
  always @(*) begin
    p1_reg[0] = p_reg[0];
    g1_reg[0] = g_reg[0];
    p1_reg[1] = p_reg[1] & p_reg[0];
    g1_reg[1] = (p_reg[1] & g_reg[0]) | g_reg[1];
    p1_reg[2] = p_reg[2] & p_reg[1];
    g1_reg[2] = (p_reg[2] & g_reg[1]) | g_reg[2];
    p1_reg[3] = p_reg[3] & p_reg[2];
    g1_reg[3] = (p_reg[3] & g_reg[2]) | g_reg[3];
  end
  
  // Stage 3: Second level prefix computation
  always @(*) begin
    p2_reg[0] = p1_reg[0];
    g2_reg[0] = g1_reg[0];
    p2_reg[1] = p1_reg[1];
    g2_reg[1] = g1_reg[1];
    p2_reg[2] = p1_reg[2] & p1_reg[0];
    g2_reg[2] = (p1_reg[2] & g1_reg[0]) | g1_reg[2];
    p2_reg[3] = p1_reg[3] & p1_reg[1];
    g2_reg[3] = (p1_reg[3] & g1_reg[1]) | g1_reg[3];
  end
  
  // Stage 4: Carry computation
  always @(*) begin
    carry_reg[0] = 1'b0;
    carry_reg[1] = g2_reg[0];
    carry_reg[2] = g2_reg[1];
    carry_reg[3] = g2_reg[2];
  end
  
  // Stage 5: Sum computation
  always @(*) begin
    sum_reg = p_reg ^ {carry_reg[2:0], 1'b0};
  end
  
  // Stage 6: Grant and count update
  always @(*) begin
    if (requests[count_reg]) begin
      grant_reg = (1 << count_reg);
      next_count = sum_reg[1:0];
    end else begin
      grant_reg = 4'b0000;
      next_count = sum_reg[1:0];
    end
  end
  
  // Pipeline registers
  always @(posedge clock) begin
    if (reset) begin
      count_reg <= 2'b00;
      grants <= 4'b0000;
    end else begin
      count_reg <= next_count;
      grants <= grant_reg;
    end
  end

endmodule