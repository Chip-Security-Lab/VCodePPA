module reset_status_register (
  input wire clk,
  input wire clear,
  input wire pwr_rst,
  input wire wdt_rst,
  input wire sw_rst,
  input wire ext_rst,
  output reg [7:0] rst_status
);
  always @(posedge clk or posedge pwr_rst) begin
    if (pwr_rst)
      rst_status <= 8'h01;
    else if (clear)
      rst_status <= 8'h00;
    else begin
      if (wdt_rst) rst_status[1] <= 1'b1;
      if (sw_rst)  rst_status[2] <= 1'b1;
      if (ext_rst) rst_status[3] <= 1'b1;
    end
  end
endmodule