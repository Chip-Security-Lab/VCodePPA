//SystemVerilog
module bidir_parity_module(
  input [15:0] data,
  input even_odd_sel,  // 0-even, 1-odd
  output reg parity_out
);
  wire parity_temp;
  wire [1:0] mux_sel;

  assign parity_temp = ^data;
  assign mux_sel = {even_odd_sel, parity_temp};

  always @(*) begin
    if (mux_sel == 2'b10) begin
      parity_out = 1'b1;
    end else if (mux_sel == 2'b01) begin
      parity_out = 1'b0;
    end else begin
      parity_out = parity_temp;
    end
  end
endmodule