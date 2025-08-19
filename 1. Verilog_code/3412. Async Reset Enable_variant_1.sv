//SystemVerilog
module RD2(
  input wire clk,
  input wire rst_n,
  input wire en,
  input wire [7:0] data_in,
  output wire [7:0] data_out
);

  // Stage 1 registers
  reg [7:0] stage1_data;
  reg stage1_valid;
  
  // Stage 2 registers
  reg [7:0] stage2_data;
  reg stage2_valid;
  
  // Stage 3 registers (output stage)
  reg [7:0] stage3_data;
  reg stage3_valid;
  
  // Stage 1: Input registration
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      stage1_data <= 8'd0;
      stage1_valid <= 1'b0;
    end else begin
      stage1_data <= en ? data_in : stage1_data;
      stage1_valid <= en;
    end
  end
  
  // Stage 2: Processing stage (in a real design, computation would happen here)
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      stage2_data <= 8'd0;
      stage2_valid <= 1'b0;
    end else begin
      stage2_data <= stage1_data;
      stage2_valid <= stage1_valid;
    end
  end
  
  // Stage 3: Output stage
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      stage3_data <= 8'd0;
      stage3_valid <= 1'b0;
    end else begin
      stage3_data <= stage2_data;
      stage3_valid <= stage2_valid;
    end
  end
  
  // Output assignment
  assign data_out = stage3_data;

endmodule