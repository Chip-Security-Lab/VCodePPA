module reset_freq_counter(
  input clk, rst_n,
  input ext_rst_n, wdt_rst_n,
  output reg [7:0] ext_rst_count,
  output reg [7:0] wdt_rst_count,
  output reg any_reset
);
  reg ext_rst_prev, wdt_rst_prev;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ext_rst_count <= 8'h00; wdt_rst_count <= 8'h00;
      ext_rst_prev <= 1'b1; wdt_rst_prev <= 1'b1;
      any_reset <= 1'b0;
    end else begin
      ext_rst_prev <= ext_rst_n; wdt_rst_prev <= wdt_rst_n;
      
      if (ext_rst_prev && !ext_rst_n) ext_rst_count <= ext_rst_count + 1;
      if (wdt_rst_prev && !wdt_rst_n) wdt_rst_count <= wdt_rst_count + 1;
      any_reset <= !ext_rst_n || !wdt_rst_n;
    end
  end
endmodule