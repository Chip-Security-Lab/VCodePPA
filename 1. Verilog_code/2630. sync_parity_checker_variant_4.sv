//SystemVerilog
module sync_parity_checker_pipeline(
  input clk, rst,
  input [7:0] data,
  input parity_in,
  input req,
  output reg ack,
  output reg error,
  output reg [3:0] error_count
);

  // Stage 1 registers
  reg data_processed_stage1;
  reg [7:0] data_reg_stage1;
  reg parity_reg_stage1;
  
  // Stage 2 registers
  reg data_processed_stage2;
  reg [7:0] data_reg_stage2;
  reg parity_reg_stage2;

  // Stage 3 registers
  reg error_stage3;
  reg [3:0] error_count_stage3;

  // Kogge-Stone adder signals
  wire [7:0] g_stage1, p_stage1;
  wire [7:0] g_stage2, p_stage2;
  wire [7:0] g_stage3, p_stage3;
  wire [7:0] sum;
  wire carry_out;

  // Generate and Propagate computation - Stage 1
  assign g_stage1 = data_reg_stage2 & {8{1'b1}};
  assign p_stage1 = data_reg_stage2 ^ {8{1'b1}};

  // Prefix computation - Stage 2
  assign g_stage2[0] = g_stage1[0];
  assign p_stage2[0] = p_stage1[0];
  
  genvar i;
  generate
    for (i = 1; i < 8; i = i + 1) begin : prefix_stage2
      assign g_stage2[i] = g_stage1[i] | (p_stage1[i] & g_stage1[i-1]);
      assign p_stage2[i] = p_stage1[i] & p_stage1[i-1];
    end
  endgenerate

  // Prefix computation - Stage 3
  assign g_stage3[0] = g_stage2[0];
  assign p_stage3[0] = p_stage2[0];
  
  generate
    for (i = 1; i < 8; i = i + 1) begin : prefix_stage3
      assign g_stage3[i] = g_stage2[i] | (p_stage2[i] & g_stage2[i-1]);
      assign p_stage3[i] = p_stage2[i] & p_stage2[i-1];
    end
  endgenerate

  // Sum computation
  assign sum[0] = p_stage1[0];
  generate
    for (i = 1; i < 8; i = i + 1) begin : sum_computation
      assign sum[i] = p_stage1[i] ^ g_stage3[i-1];
    end
  endgenerate
  assign carry_out = g_stage3[7];

  // Stage 1 handshake control
  always @(posedge clk) begin
    if (rst) begin
      ack <= 1'b0;
      data_processed_stage1 <= 1'b0;
      data_reg_stage1 <= 8'd0;
      parity_reg_stage1 <= 1'b0;
    end else begin
      if (req && !data_processed_stage1) begin
        data_reg_stage1 <= data;
        parity_reg_stage1 <= parity_in;
        data_processed_stage1 <= 1'b1;
        ack <= 1'b1;
      end else if (!req) begin
        data_processed_stage1 <= 1'b0;
        ack <= 1'b0;
      end
    end
  end

  // Stage 2 data transfer
  always @(posedge clk) begin
    if (rst) begin
      data_processed_stage2 <= 1'b0;
      data_reg_stage2 <= 8'd0;
      parity_reg_stage2 <= 1'b0;
    end else if (data_processed_stage1 && ack) begin
      data_reg_stage2 <= data_reg_stage1;
      parity_reg_stage2 <= parity_reg_stage1;
      data_processed_stage2 <= 1'b1;
    end else begin
      data_processed_stage2 <= 1'b0;
    end
  end

  // Stage 3 error detection
  always @(posedge clk) begin
    if (rst) begin
      error <= 1'b0;
      error_count_stage3 <= 4'd0;
    end else if (data_processed_stage2) begin
      error_stage3 <= (^sum) ^ parity_reg_stage2;
      if (error_stage3)
        error_count_stage3 <= error_count_stage3 + 1'b1;
    end
  end

  // Final output assignment
  always @(posedge clk) begin
    if (rst) begin
      error <= 1'b0;
      error_count <= 4'd0;
    end else begin
      error <= error_stage3;
      error_count <= error_count_stage3;
    end
  end

endmodule