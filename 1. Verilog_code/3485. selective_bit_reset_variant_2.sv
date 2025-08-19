//SystemVerilog
module selective_bit_reset(
  input wire clk, rst_n,
  input wire reset_bit0, reset_bit1, reset_bit2,
  input wire [2:0] data_in,
  output reg [2:0] data_out
);
  // Stage 1 signals
  reg [2:0] data_stage1;
  reg reset_bit0_stage1, reset_bit1_stage1, reset_bit2_stage1;
  
  // Stage 2 signals
  reg [2:0] data_stage2;
  reg reset_bit0_stage2, reset_bit1_stage2, reset_bit2_stage2;
  
  // Stage 1: Input registration
  always @(posedge clk) begin
    if (!rst_n) begin
      data_stage1 <= 3'b000;
      reset_bit0_stage1 <= 1'b0;
      reset_bit1_stage1 <= 1'b0;
      reset_bit2_stage1 <= 1'b0;
    end else begin
      data_stage1 <= data_in;
      reset_bit0_stage1 <= reset_bit0;
      reset_bit1_stage1 <= reset_bit1;
      reset_bit2_stage1 <= reset_bit2;
    end
  end
  
  // Stage 2: Intermediate processing
  always @(posedge clk) begin
    if (!rst_n) begin
      data_stage2 <= 3'b000;
      reset_bit0_stage2 <= 1'b0;
      reset_bit1_stage2 <= 1'b0;
      reset_bit2_stage2 <= 1'b0;
    end else begin
      data_stage2 <= data_stage1;
      reset_bit0_stage2 <= reset_bit0_stage1;
      reset_bit1_stage2 <= reset_bit1_stage1;
      reset_bit2_stage2 <= reset_bit2_stage1;
    end
  end
  
  // Stage 3: Final reset logic and output - flattened if-else structure
  always @(posedge clk) begin
    if (!rst_n) begin
      data_out <= 3'b000;
    end else if (reset_bit0_stage2 && reset_bit1_stage2 && reset_bit2_stage2) begin
      data_out <= 3'b000;
    end else if (reset_bit0_stage2 && reset_bit1_stage2 && !reset_bit2_stage2) begin
      data_out <= {data_stage2[2], 2'b00};
    end else if (reset_bit0_stage2 && !reset_bit1_stage2 && reset_bit2_stage2) begin
      data_out <= {1'b0, data_stage2[1], 1'b0};
    end else if (!reset_bit0_stage2 && reset_bit1_stage2 && reset_bit2_stage2) begin
      data_out <= {2'b00, data_stage2[0]};
    end else if (reset_bit0_stage2 && !reset_bit1_stage2 && !reset_bit2_stage2) begin
      data_out <= {data_stage2[2:1], 1'b0};
    end else if (!reset_bit0_stage2 && reset_bit1_stage2 && !reset_bit2_stage2) begin
      data_out <= {data_stage2[2], 1'b0, data_stage2[0]};
    end else if (!reset_bit0_stage2 && !reset_bit1_stage2 && reset_bit2_stage2) begin
      data_out <= {1'b0, data_stage2[1:0]};
    end else begin
      data_out <= data_stage2;
    end
  end
endmodule