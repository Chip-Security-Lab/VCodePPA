//SystemVerilog
module counter_arbiter(
  input wire clock, reset,
  input wire [3:0] requests,
  output reg [3:0] grants
);
  reg [1:0] count_stage1;
  reg [1:0] count_stage2;
  reg [3:0] requests_stage1;
  reg [3:0] grants_stage1;
  
  // Stage 1: Request capture and count update
  always @(posedge clock) begin
    if (reset) begin
      count_stage1 <= 2'b00;
      requests_stage1 <= 4'b0000;
      grants_stage1 <= 4'b0000;
    end else begin
      requests_stage1 <= requests;
      count_stage1 <= count_stage2;
      grants_stage1 <= 4'b0000;
    end
  end
  
  // Stage 2: Grant generation and count increment
  always @(posedge clock) begin
    if (reset) begin
      count_stage2 <= 2'b00;
      grants <= 4'b0000;
    end else begin
      if (requests_stage1[count_stage1]) begin
        grants <= (1 << count_stage1);
      end else begin
        grants <= 4'b0000;
      end
      count_stage2 <= count_stage1 + 1'b1;
    end
  end
endmodule