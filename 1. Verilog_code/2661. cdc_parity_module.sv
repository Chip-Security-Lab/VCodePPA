module cdc_parity_module(
  input src_clk, dst_clk, src_rst_n,
  input [7:0] src_data,
  output reg dst_parity
);
  reg src_parity;
  reg [2:0] sync_reg;
  
  always @(posedge src_clk or negedge src_rst_n) begin
    if (!src_rst_n)
      src_parity <= 1'b0;
    else
      src_parity <= ^src_data;
  end
  
  always @(posedge dst_clk) begin
    sync_reg <= {sync_reg[1:0], src_parity};
    dst_parity <= sync_reg[2];
  end
endmodule