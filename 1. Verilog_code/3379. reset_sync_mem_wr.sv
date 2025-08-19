module reset_sync_mem_wr(
  input  wire clk,
  input  wire rst_n,
  input  wire wr_data,
  output reg  mem_out
);
  reg mem_reg;
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      mem_reg <= 1'b0;
      mem_out <= 1'b0;
    end else begin
      mem_reg <= wr_data;
      mem_out <= mem_reg;
    end
  end
endmodule
