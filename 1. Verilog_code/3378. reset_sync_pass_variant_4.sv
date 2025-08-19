//SystemVerilog
module reset_sync_pass(
  input  wire clk,
  input  wire rst_n,
  input  wire data_in,
  output reg  data_out
);
  reg stg;
  reg data_in_reg;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data_in_reg <= 1'b0;
      stg         <= 1'b0;
      data_out    <= 1'b0;
    end else begin
      data_in_reg <= data_in;
      stg         <= data_in_reg;
      data_out    <= stg;
    end
  end
endmodule