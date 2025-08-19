module tdm_parity_gen(
  input clk, rst_n,
  input [7:0] stream_a, stream_b,
  input stream_sel,
  output reg parity_out
);
  reg [7:0] selected_stream;
  
  always @(posedge clk) begin
    if (!rst_n) begin
      selected_stream <= 8'h0;
      parity_out <= 1'b0;
    end else begin
      selected_stream <= stream_sel ? stream_b : stream_a;
      parity_out <= ^selected_stream;
    end
  end
endmodule