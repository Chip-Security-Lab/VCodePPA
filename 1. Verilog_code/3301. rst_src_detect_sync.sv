module rst_src_detect_sync(
  input wire clk, rst_n,
  input wire por_n, wdt_n, ext_n, sw_n,
  output reg [3:0] rst_src
);
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rst_src <= 4'b0000;
    end else begin
      rst_src[0] <= ~por_n;
      rst_src[1] <= ~wdt_n;
      rst_src[2] <= ~ext_n;
      rst_src[3] <= ~sw_n;
    end
  end
endmodule