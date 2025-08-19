module reset_sync_two_always(
  input  wire clk,
  input  wire rst_n,
  output reg  out_rst
);
  reg stg1;
  always @(posedge clk or negedge rst_n)
    if(!rst_n) stg1 <= 1'b0; else stg1 <= 1'b1;
  always @(posedge clk or negedge rst_n)
    if(!rst_n) out_rst <= 1'b0; else out_rst <= stg1;
endmodule

