//SystemVerilog
module lut_arbiter(
  input clk, rst,
  input [3:0] data_in,
  input valid_in,
  output reg ready_out,
  output reg [3:0] data_out,
  output reg valid_out,
  input ready_in
);

  reg [3:0] lut [0:15];
  reg [3:0] request_stage1;
  reg [3:0] request_stage2;
  reg [3:0] lut_result_stage2;
  reg valid_stage1;
  reg valid_stage2;
  reg processing_stage1;
  reg processing_stage2;
  
  always @(posedge clk) begin
    if (rst) begin
      lut[0] <= 4'b0000; lut[1] <= 4'b0001; 
      lut[2] <= 4'b0010; lut[3] <= 4'b0001;
      // More initialization would follow
      data_out <= 4'b0000;
      valid_out <= 1'b0;
      ready_out <= 1'b1;
      processing_stage1 <= 1'b0;
      processing_stage2 <= 1'b0;
      valid_stage1 <= 1'b0;
      valid_stage2 <= 1'b0;
    end else begin
      // Stage 1: Input and LUT access
      if (valid_in && ready_out && !processing_stage1) begin
        request_stage1 <= data_in;
        ready_out <= 1'b0;
        processing_stage1 <= 1'b1;
        valid_stage1 <= 1'b1;
      end else if (processing_stage2 && ready_in) begin
        ready_out <= 1'b1;
        valid_stage1 <= 1'b0;
      end

      // Stage 2: LUT result processing
      if (valid_stage1) begin
        request_stage2 <= request_stage1;
        lut_result_stage2 <= lut[request_stage1];
        processing_stage2 <= 1'b1;
        valid_stage2 <= 1'b1;
        processing_stage1 <= 1'b0;
      end

      // Stage 3: Output
      if (processing_stage2 && ready_in) begin
        data_out <= lut_result_stage2;
        valid_out <= 1'b1;
        processing_stage2 <= 1'b0;
        valid_stage2 <= 1'b0;
      end else if (!ready_in) begin
        valid_out <= 1'b0;
      end
    end
  end
endmodule