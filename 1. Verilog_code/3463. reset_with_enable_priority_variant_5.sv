//SystemVerilog
module reset_with_enable_priority #(parameter WIDTH = 4)(
  input clk, rst, en,
  output reg [WIDTH-1:0] data_out
);
  reg [WIDTH-1:0] next_data;
  reg [WIDTH-1:0] internal_data;
  
  always @(*) begin
    if (rst) begin
      next_data = {WIDTH{1'b0}};
    end else if (en) begin
      next_data = internal_data + 1'b1;
    end else begin
      next_data = internal_data;
    end
  end
  
  always @(posedge clk) begin
    internal_data <= next_data;
    data_out <= next_data;
  end
endmodule