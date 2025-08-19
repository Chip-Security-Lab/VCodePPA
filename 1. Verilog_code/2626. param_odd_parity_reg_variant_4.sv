//SystemVerilog
module param_odd_parity_reg_top #(
  parameter DATA_W = 32
)(
  input clk,
  input [DATA_W-1:0] data,
  output reg parity_bit
);

  wire parity;
  parity_calculator #(.DATA_W(DATA_W)) u_parity_calculator (
    .clk(clk),
    .data(data),
    .parity(parity)
  );

  always @(posedge clk) begin
    parity_bit <= parity;
  end

endmodule

module parity_calculator #(
  parameter DATA_W = 32
)(
  input clk,
  input [DATA_W-1:0] data,
  output reg parity
);

  reg [DATA_W/2-1:0] stage1_parity;
  reg [DATA_W/4-1:0] stage2_parity;
  reg [DATA_W/8-1:0] stage3_parity;
  reg [DATA_W/16-1:0] stage4_parity;
  reg [DATA_W/32-1:0] stage5_parity;

  always @(posedge clk) begin
    // Stage 1: Calculate parity for first half
    stage1_parity <= ^data[DATA_W-1:DATA_W/2];
    
    // Stage 2: Calculate parity for second half
    stage2_parity <= ^data[DATA_W/2-1:0];
    
    // Stage 3: Combine first half results
    stage3_parity <= ^stage1_parity;
    
    // Stage 4: Combine second half results
    stage4_parity <= ^stage2_parity;
    
    // Stage 5: Final combination
    stage5_parity <= stage3_parity ^ stage4_parity;
    
    // Final stage: Invert for odd parity
    parity <= ~stage5_parity;
  end

endmodule