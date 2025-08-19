//SystemVerilog
module rst_src_detect_sync(
  input  wire        clk,
  input  wire        rst_n,
  input  wire        por_n,
  input  wire        wdt_n,
  input  wire        ext_n,
  input  wire        sw_n,
  output reg  [3:0]  rst_src
);

  wire [3:0] rst_active;

  assign rst_active = {~sw_n, ~ext_n, ~wdt_n, ~por_n};

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rst_src <= 4'b0000;
    end else begin
      rst_src <= rst_active;
    end
  end

endmodule