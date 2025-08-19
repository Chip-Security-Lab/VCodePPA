//SystemVerilog
module reset_sync_two_always(
  input  wire clk,
  input  wire rst_n,
  output wire out_rst
);
  reg stg1, stg2;
  
  always @(posedge clk or negedge rst_n)
    if(!rst_n) begin
      stg1 <= 1'b0;
      stg2 <= 1'b0;
    end else begin
      stg1 <= 1'b1;
      stg2 <= stg1;
    end
    
  assign out_rst = stg2;
endmodule