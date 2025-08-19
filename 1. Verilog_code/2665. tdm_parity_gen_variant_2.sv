//SystemVerilog
module tdm_parity_gen(
  input clk, rst_n,
  input [7:0] stream_a, stream_b,
  input stream_sel,
  output reg parity_out
);

  // Stage 1: Stream selection and initial parity calculation
  reg [7:0] selected_stream_stage1;
  reg parity_stage1;
  
  // Stage 2: Final parity calculation
  reg parity_stage2;
  
  // Valid signals for pipeline control
  reg valid_stage1;
  reg valid_stage2;
  
  // Stage 1 logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      selected_stream_stage1 <= 8'b0;
      parity_stage1 <= 1'b0;
      valid_stage1 <= 1'b0;
    end else begin
      selected_stream_stage1 <= stream_sel ? stream_b : stream_a;
      parity_stage1 <= ^(stream_sel ? stream_b : stream_a);
      valid_stage1 <= 1'b1;
    end
  end
  
  // Stage 2 logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      parity_stage2 <= 1'b0;
      valid_stage2 <= 1'b0;
    end else begin
      parity_stage2 <= parity_stage1;
      valid_stage2 <= valid_stage1;
    end
  end
  
  // Output stage
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      parity_out <= 1'b0;
    end else begin
      parity_out <= valid_stage2 ? parity_stage2 : 1'b0;
    end
  end

endmodule