//SystemVerilog
module pipelined_arbiter #(parameter WIDTH=4) (
  input clk, rst,
  input [WIDTH-1:0] req_in,
  output reg [WIDTH-1:0] grant_out
);
  // Stage 1: Input registers
  reg [WIDTH-1:0] req_stage1;
  
  // Stage 2: Request buffering
  reg [WIDTH-1:0] req_stage2_buf1, req_stage2_buf2;
  
  // Stage 3: Subtraction preparation
  reg [7:0] subtractor_a_stage3;
  reg [7:0] subtractor_b_stage3;
  reg subtract_invert_flag_stage3;
  
  // Stage 4: Subtraction execution
  wire [7:0] operand_b_internal_stage4;
  wire [7:0] diff_internal_stage4;
  reg [7:0] diff_result_stage4;
  
  // Stage 5: Active request detection
  reg b1_stage5;
  reg [WIDTH-1:0] req_stage5_buf1, req_stage5_buf2;
  
  // Stage 6: Priority arbitration preparation
  reg b1_stage6_buf1, b1_stage6_buf2;
  reg [WIDTH-1:0] req_stage6_buf1, req_stage6_buf2;
  
  // Stage 7: Priority arbitration execution
  reg [WIDTH-1:0] grant_stage7;
  
  // Stage 8: Grant buffering
  reg [WIDTH-1:0] grant_stage8_buf1, grant_stage8_buf2;
  
  // Stage 9: Pre-output stage
  reg [WIDTH-1:0] grant_stage9;
  
  // 条件反相减法器实现
  assign operand_b_internal_stage4 = subtract_invert_flag_stage3 ? ~subtractor_b_stage3 : subtractor_b_stage3;
  assign diff_internal_stage4 = subtractor_a_stage3 + operand_b_internal_stage4 + subtract_invert_flag_stage3;
  
  always @(posedge clk) begin
    if (rst) begin
      // Reset all pipeline registers
      req_stage1 <= 0;
      
      req_stage2_buf1 <= 0;
      req_stage2_buf2 <= 0;
      
      subtractor_a_stage3 <= 8'h0;
      subtractor_b_stage3 <= 8'h0;
      subtract_invert_flag_stage3 <= 1'b0;
      
      diff_result_stage4 <= 8'h0;
      
      b1_stage5 <= 0;
      req_stage5_buf1 <= 0;
      req_stage5_buf2 <= 0;
      
      b1_stage6_buf1 <= 0;
      b1_stage6_buf2 <= 0;
      req_stage6_buf1 <= 0;
      req_stage6_buf2 <= 0;
      
      grant_stage7 <= 0;
      
      grant_stage8_buf1 <= 0;
      grant_stage8_buf2 <= 0;
      
      grant_stage9 <= 0;
      
      grant_out <= 0;
    end else begin
      // Stage 1: Input registration
      req_stage1 <= req_in;
      
      // Stage 2: Request buffering
      req_stage2_buf1 <= req_stage1;
      req_stage2_buf2 <= req_stage1;
      
      // Stage 3: Subtraction preparation
      subtractor_a_stage3 <= {4'h0, req_stage2_buf1};
      subtractor_b_stage3 <= 8'h0;
      subtract_invert_flag_stage3 <= 1'b1; // A - B = A + ~B + 1
      
      // Stage 4: Subtraction execution
      diff_result_stage4 <= diff_internal_stage4;
      
      // Stage 5: Active request detection
      b1_stage5 <= |diff_result_stage4[3:0];
      req_stage5_buf1 <= req_stage2_buf2;  // Forward request data
      req_stage5_buf2 <= req_stage2_buf1;  // Forward request data
      
      // Stage 6: Priority arbitration preparation
      b1_stage6_buf1 <= b1_stage5;
      b1_stage6_buf2 <= b1_stage5;
      req_stage6_buf1 <= req_stage5_buf1;
      req_stage6_buf2 <= req_stage5_buf2;
      
      // Stage 7: Priority arbitration execution
      if (b1_stage6_buf1) begin
        grant_stage7 <= 0;
        if (req_stage6_buf1[0]) grant_stage7[0] <= 1'b1;
        else if (req_stage6_buf1[1]) grant_stage7[1] <= 1'b1;
        else if (req_stage6_buf2[2]) grant_stage7[2] <= 1'b1;
        else if (req_stage6_buf2[3]) grant_stage7[3] <= 1'b1;
      end else grant_stage7 <= 0;
      
      // Stage 8: Grant buffering
      grant_stage8_buf1 <= grant_stage7;
      grant_stage8_buf2 <= grant_stage7;
      
      // Stage 9: Pre-output stage
      grant_stage9 <= grant_stage8_buf2;
      
      // Output Stage
      grant_out <= grant_stage9;
    end
  end
endmodule