//SystemVerilog
module reset_sync_multi_bit #(parameter WIDTH = 4) (
  input  wire             clk,
  input  wire [WIDTH-1:0] rst_in,
  output reg  [WIDTH-1:0] rst_out
);
  reg [WIDTH-1:0] stage;
  
  always @(posedge clk or negedge rst_in[0]) begin
    if (rst_in[0]) begin
      stage   <= {WIDTH{1'b1}};
      rst_out <= stage;
    end else begin
      stage   <= {WIDTH{1'b0}};
      rst_out <= {WIDTH{1'b0}};
    end
  end
endmodule