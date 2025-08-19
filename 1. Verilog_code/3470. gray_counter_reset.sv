module gray_counter_reset #(parameter WIDTH = 4)(
  input clk, rst, enable,
  output reg [WIDTH-1:0] gray_count
);
  reg [WIDTH-1:0] binary_count;
  
  always @(posedge clk) begin
    if (rst) begin
      binary_count <= 0;
      gray_count <= 0;
    end else if (enable) begin
      binary_count <= binary_count + 1;
      gray_count <= binary_count ^ (binary_count >> 1);
    end
  end
endmodule
