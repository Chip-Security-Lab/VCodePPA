module reset_sync_pass(
  input  wire clk,
  input  wire rst_n,
  input  wire data_in,
  output reg  data_out
);
  reg stg;
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      stg      <= 1'b0;
      data_out <= 1'b0;
    end else begin
      stg      <= data_in;
      data_out <= stg;
    end
  end
endmodule

