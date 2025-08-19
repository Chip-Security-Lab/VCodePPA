module pipeline_stage_reset #(parameter WIDTH = 32)(
  input clk, rst,
  input [WIDTH-1:0] data_in,
  input valid_in,
  output reg [WIDTH-1:0] data_out,
  output reg valid_out
);
  always @(posedge clk) begin
    if (rst) begin
      data_out <= {WIDTH{1'b0}};
      valid_out <= 1'b0;
    end else begin
      data_out <= data_in;
      valid_out <= valid_in;
    end
  end
endmodule
