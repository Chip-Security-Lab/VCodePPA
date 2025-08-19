//SystemVerilog
module round_robin_arbiter #(parameter WIDTH=4) (
  input wire clock, reset,
  input wire [WIDTH-1:0] request,
  input wire req_valid,
  output reg [WIDTH-1:0] grant,
  output reg grant_valid
);
  // Stage 1 registers
  reg [WIDTH-1:0] mask;
  reg [WIDTH-1:0] request_stage1;
  reg req_valid_stage1;
  
  // Stage 2 registers
  reg [WIDTH-1:0] masked_req_stage2;
  reg [WIDTH-1:0] original_req_stage2;
  reg req_valid_stage2;
  
  // Stage 3 registers
  reg [WIDTH-1:0] grant_stage3;
  reg grant_valid_stage3;
  reg [WIDTH-1:0] nxt_mask_stage3;

  // Stage 1: Request and mask processing
  wire [WIDTH-1:0] masked_req = request & ~mask;
  
  always @(posedge clock) begin
    if (reset) begin
      request_stage1 <= 0;
      req_valid_stage1 <= 0;
      masked_req_stage2 <= 0;
      original_req_stage2 <= 0;
      req_valid_stage2 <= 0;
    end else begin
      // Stage 1 to Stage 2 pipeline registers
      request_stage1 <= request;
      req_valid_stage1 <= req_valid;
      
      // Stage 2 registers
      masked_req_stage2 <= masked_req;
      original_req_stage2 <= request;
      req_valid_stage2 <= req_valid_stage1;
    end
  end
  
  // Stage 2: Priority encoding logic
  reg [WIDTH-1:0] grant_stage2;
  reg [WIDTH-1:0] nxt_mask_stage2;
  reg use_masked_req_stage2;
  
  always @(*) begin
    grant_stage2 = 0;
    nxt_mask_stage2 = mask;
    use_masked_req_stage2 = |masked_req_stage2;
    
    if (use_masked_req_stage2) begin
      casez(masked_req_stage2)
        4'b???1: grant_stage2 = 4'b0001;
        4'b??10: grant_stage2 = 4'b0010;
        4'b?100: grant_stage2 = 4'b0100;
        4'b1000: grant_stage2 = 4'b1000;
        default: grant_stage2 = 4'b0000;
      endcase
    end else if (|original_req_stage2) begin
      casez(original_req_stage2)
        4'b???1: grant_stage2 = 4'b0001;
        4'b??10: grant_stage2 = 4'b0010;
        4'b?100: grant_stage2 = 4'b0100;
        4'b1000: grant_stage2 = 4'b1000;
        default: grant_stage2 = 4'b0000;
      endcase
    end
    
    if (|grant_stage2) begin
      nxt_mask_stage2 = {grant_stage2[WIDTH-2:0], grant_stage2[WIDTH-1]};
    end
  end
  
  // Stage 3: Output and mask update
  always @(posedge clock) begin
    if (reset) begin
      mask <= 0;
      grant_stage3 <= 0;
      grant_valid_stage3 <= 0;
      nxt_mask_stage3 <= 0;
      grant <= 0;
      grant_valid <= 0;
    end else begin
      // Stage 2 to Stage 3 pipeline registers
      grant_stage3 <= grant_stage2;
      grant_valid_stage3 <= req_valid_stage2;
      nxt_mask_stage3 <= nxt_mask_stage2;
      
      // Stage 3 to output registers
      grant <= grant_stage3;
      grant_valid <= grant_valid_stage3;
      
      // Update mask register (feedback from stage 3)
      if (grant_valid_stage3) begin
        mask <= nxt_mask_stage3;
      end
    end
  end
endmodule