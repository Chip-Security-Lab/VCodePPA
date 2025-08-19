//SystemVerilog
module serial_parity_calc(
  input clk, rst, bit_in, start,
  output reg parity_done,
  output reg parity_bit
);

  // Pipeline stage 1 registers
  reg [3:0] bit_count_stage1;
  reg parity_bit_stage1;
  reg valid_stage1;
  
  // Pipeline stage 2 registers
  reg [3:0] bit_count_stage2;
  reg parity_bit_stage2;
  reg valid_stage2;
  
  // Pipeline stage 3 registers
  reg [3:0] bit_count_stage3;
  reg parity_bit_stage3;
  reg valid_stage3;
  
  // Stage 1: Input processing
  always @(posedge clk) begin
    if (rst) begin
      bit_count_stage1 <= 4'd0;
      parity_bit_stage1 <= 1'b0;
      valid_stage1 <= 1'b0;
    end else if (start) begin
      bit_count_stage1 <= 4'd0;
      parity_bit_stage1 <= 1'b0;
      valid_stage1 <= 1'b1;
    end else begin
      if (bit_count_stage1 < 4'd8) begin
        parity_bit_stage1 <= parity_bit_stage1 ^ bit_in;
        bit_count_stage1 <= bit_count_stage1 + 1'b1;
        valid_stage1 <= 1'b1;
      end else begin
        valid_stage1 <= 1'b0;
      end
    end
  end
  
  // Stage 2: Intermediate processing
  always @(posedge clk) begin
    if (rst) begin
      bit_count_stage2 <= 4'd0;
      parity_bit_stage2 <= 1'b0;
      valid_stage2 <= 1'b0;
    end else begin
      bit_count_stage2 <= bit_count_stage1;
      parity_bit_stage2 <= parity_bit_stage1;
      valid_stage2 <= valid_stage1;
    end
  end
  
  // Stage 3: Output processing
  always @(posedge clk) begin
    if (rst) begin
      bit_count_stage3 <= 4'd0;
      parity_bit_stage3 <= 1'b0;
      valid_stage3 <= 1'b0;
      parity_done <= 1'b0;
      parity_bit <= 1'b0;
    end else begin
      bit_count_stage3 <= bit_count_stage2;
      parity_bit_stage3 <= parity_bit_stage2;
      valid_stage3 <= valid_stage2;
      
      if (valid_stage3) begin
        parity_done <= (bit_count_stage3 == 4'd7);
        parity_bit <= parity_bit_stage3;
      end else begin
        parity_done <= 1'b0;
      end
    end
  end

endmodule