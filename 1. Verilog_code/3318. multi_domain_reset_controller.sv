module multi_domain_reset_controller(
  input clk, global_rst_n,
  input por_n, ext_n, wdt_n, sw_n,
  output reg core_rst_n, periph_rst_n, mem_rst_n
);
  wire any_reset = ~por_n | ~ext_n | ~wdt_n | ~sw_n;
  reg [1:0] reset_count = 2'b00;
  
  always @(posedge clk or negedge global_rst_n) begin
    if (!global_rst_n) begin
      reset_count <= 2'b00;
      core_rst_n <= 1'b0;
      periph_rst_n <= 1'b0;
      mem_rst_n <= 1'b0;
    end else if (any_reset) begin
      reset_count <= 2'b00;
      core_rst_n <= 1'b0;
      periph_rst_n <= 1'b0;
      mem_rst_n <= 1'b0;
    end else begin
      reset_count <= (reset_count == 2'b11) ? 2'b11 : reset_count + 1;
      core_rst_n <= (reset_count >= 2'b01);
      periph_rst_n <= (reset_count >= 2'b10);
      mem_rst_n <= (reset_count == 2'b11);
    end
  end
endmodule

