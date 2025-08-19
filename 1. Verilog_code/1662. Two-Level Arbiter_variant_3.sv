//SystemVerilog
module two_level_arbiter(
  input clock, reset,
  input [1:0] group_sel,
  input [7:0] requests,
  output reg [7:0] grants
);

  wire [1:0] group_reqs;
  wire [1:0] group_grants;
  reg [1:0] group_priority;
  reg [7:0] grants_next;
  reg [1:0] group_sel_reg;
  reg [7:0] requests_reg;
  
  // Optimized group request detection
  assign group_reqs = {|requests_reg[7:4], |requests_reg[3:0]};
  
  // Optimized group arbitration
  assign group_grants = group_reqs & ~group_priority;
  
  // Register inputs
  always @(posedge clock) begin
    if (reset) begin
      group_sel_reg <= 2'b0;
      requests_reg <= 8'b0;
    end else begin
      group_sel_reg <= group_sel;
      requests_reg <= requests;
    end
  end
  
  // Optimized within-group arbitration
  always @(*) begin
    grants_next = 8'b0;
    case (group_sel_reg)
      2'b00: grants_next[0] = requests_reg[0];
      2'b01: grants_next[1] = requests_reg[1];
      2'b10: grants_next[2] = requests_reg[2];
      2'b11: grants_next[3] = requests_reg[3];
    endcase
    
    case (group_sel_reg)
      2'b00: grants_next[4] = requests_reg[4];
      2'b01: grants_next[5] = requests_reg[5];
      2'b10: grants_next[6] = requests_reg[6];
      2'b11: grants_next[7] = requests_reg[7];
    endcase
  end
  
  // Output register
  always @(posedge clock) begin
    if (reset) begin
      grants <= 8'b0;
      group_priority <= 2'b0;
    end else begin
      grants <= grants_next;
      if (|grants_next) begin
        group_priority <= group_sel_reg;
      end
    end
  end
endmodule