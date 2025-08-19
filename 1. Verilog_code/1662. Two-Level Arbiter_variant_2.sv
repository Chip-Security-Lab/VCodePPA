//SystemVerilog
module two_level_arbiter(
  input clock,
  input reset,
  input [1:0] group_sel,
  input [7:0] requests,
  output reg [7:0] grants,
  output reg valid,
  input ready
);

  // Pipeline stage 1: Request grouping and arbitration
  reg [1:0] group_reqs_ff;
  reg [1:0] group_grants_ff;
  reg [7:0] requests_ff;
  
  // Pipeline stage 2: Grant generation
  reg [7:0] grants_ff;
  reg valid_ff;
  
  // Group request calculation
  wire [1:0] group_reqs;
  assign group_reqs[0] = |requests[3:0];
  assign group_reqs[1] = |requests[7:4];
  
  // First pipeline stage
  always @(posedge clock) begin
    if (reset) begin
      group_reqs_ff <= 2'b0;
      requests_ff <= 8'b0;
    end else if (ready) begin
      group_reqs_ff <= group_reqs;
      requests_ff <= requests;
    end
  end
  
  // Group arbitration logic
  always @(*) begin
    group_grants_ff = 2'b0;
    if (|group_reqs_ff) begin
      case (group_sel)
        2'b00: group_grants_ff[0] = 1'b1;
        2'b01: group_grants_ff[1] = 1'b1;
        default: group_grants_ff = group_reqs_ff;
      endcase
    end
  end
  
  // Second pipeline stage
  always @(posedge clock) begin
    if (reset) begin
      grants_ff <= 8'b0;
      valid_ff <= 1'b0;
    end else if (ready) begin
      grants_ff <= grants_next;
      valid_ff <= valid_next;
    end
  end
  
  // Grant generation logic
  reg [7:0] grants_next;
  reg valid_next;
  
  always @(*) begin
    grants_next = 8'b0;
    valid_next = 1'b0;
    
    if (|requests_ff) begin
      if (group_grants_ff[0]) begin
        grants_next[3:0] = requests_ff[3:0];
      end
      if (group_grants_ff[1]) begin
        grants_next[7:4] = requests_ff[7:4];
      end
      valid_next = 1'b1;
    end
  end
  
  // Output stage
  always @(posedge clock) begin
    if (reset) begin
      grants <= 8'b0;
      valid <= 1'b0;
    end else if (ready) begin
      grants <= grants_ff;
      valid <= valid_ff;
    end
  end
  
endmodule