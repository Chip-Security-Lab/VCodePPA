//SystemVerilog
module reset_sync_multi_bit #(parameter WIDTH = 4) (
  input  wire             clk,
  input  wire [WIDTH-1:0] rst_in,
  output reg  [WIDTH-1:0] rst_out
);
  reg [WIDTH-1:0] stage;
  wire rst_in_stable = rst_in[0];
  
  always @(posedge clk) begin
    if (rst_in_stable) begin
      stage   <= {WIDTH{1'b1}};
      rst_out <= stage;
    end
    else begin
      stage   <= {WIDTH{1'b0}};
      rst_out <= {WIDTH{1'b0}};
    end
  end
endmodule