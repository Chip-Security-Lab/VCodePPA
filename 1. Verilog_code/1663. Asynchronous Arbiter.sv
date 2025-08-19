module async_arbiter #(parameter WIDTH = 4) (
  input [WIDTH-1:0] req,
  output [WIDTH-1:0] gnt
);
  genvar i;
  
  generate
    for (i = 0; i < WIDTH; i = i + 1) begin: gen_grants
      if (i == WIDTH-1)
        assign gnt[i] = req[i];
      else
        assign gnt[i] = req[i] & (~|(req[WIDTH-1:i+1]));
    end
  endgenerate
endmodule