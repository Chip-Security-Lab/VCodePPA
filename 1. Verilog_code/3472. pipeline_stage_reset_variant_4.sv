//SystemVerilog
module pipeline_stage_reset #(parameter WIDTH = 32, parameter STAGES = 3)(
  input clk, rst,
  input [WIDTH-1:0] data_in,
  input valid_in,
  output reg [WIDTH-1:0] data_out,
  output reg valid_out
);
  // Pipeline stage registers for data
  reg [WIDTH-1:0] data_stage1, data_stage2;
  
  // Pipeline stage registers for valid signals
  reg valid_stage1, valid_stage2;
  
  // Pipeline stage 1
  always @(posedge clk) begin
    if (rst) begin
      data_stage1 <= {WIDTH{1'b0}};
      valid_stage1 <= 1'b0;
    end else begin
      data_stage1 <= data_in;
      valid_stage1 <= valid_in;
    end
  end
  
  // Pipeline stage 2
  always @(posedge clk) begin
    if (rst) begin
      data_stage2 <= {WIDTH{1'b0}};
      valid_stage2 <= 1'b0;
    end else begin
      data_stage2 <= data_stage1;
      valid_stage2 <= valid_stage1;
    end
  end
  
  // Pipeline stage 3 (output stage)
  always @(posedge clk) begin
    if (rst) begin
      data_out <= {WIDTH{1'b0}};
      valid_out <= 1'b0;
    end else begin
      data_out <= data_stage2;
      valid_out <= valid_stage2;
    end
  end
endmodule