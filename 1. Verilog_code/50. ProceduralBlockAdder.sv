module proc_adder(
  input [5:0] p, q,
  output reg [6:0] result
);
  always @(*) begin
    result = p + q; //6-bit inputs
  end
endmodule