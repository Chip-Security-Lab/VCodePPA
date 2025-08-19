//SystemVerilog
module lfsr_with_reset #(parameter WIDTH = 8)(
  input clk, async_rst, enable,
  input data_valid_in,
  output reg data_valid_out,
  output reg [WIDTH-1:0] lfsr_out
);
  // Stage 1: Compute feedback and prepare shift operation
  reg [WIDTH-1:0] lfsr_stage1;
  reg data_valid_stage1;
  wire feedback;
  
  // Buffered copies of lfsr_out to reduce fanout
  reg [WIDTH-1:0] lfsr_out_buf1;
  reg [WIDTH-1:0] lfsr_out_buf2;
  
  // Use buffered signals for feedback calculation to reduce critical path
  assign feedback = lfsr_out_buf1[7] ^ lfsr_out_buf1[3] ^ lfsr_out_buf2[2] ^ lfsr_out_buf2[1];
  
  // Buffer registers to reduce fanout of lfsr_out
  always @(posedge clk or posedge async_rst) begin
    if (async_rst) begin
      lfsr_out_buf1 <= 8'h01;
      lfsr_out_buf2 <= 8'h01;
    end else if (enable) begin
      lfsr_out_buf1 <= lfsr_out;
      lfsr_out_buf2 <= lfsr_out;
    end
  end
  
  always @(posedge clk or posedge async_rst) begin
    if (async_rst) begin
      lfsr_stage1 <= 8'h01;  // Non-zero seed
      data_valid_stage1 <= 1'b0;
    end else if (enable) begin
      lfsr_stage1 <= {lfsr_out[WIDTH-2:0], feedback};
      data_valid_stage1 <= data_valid_in;
    end
  end
  
  // Stage 2: Output stage
  always @(posedge clk or posedge async_rst) begin
    if (async_rst) begin
      lfsr_out <= 8'h01;  // Non-zero seed
      data_valid_out <= 1'b0;
    end else if (enable) begin
      lfsr_out <= lfsr_stage1;
      data_valid_out <= data_valid_stage1;
    end
  end
endmodule