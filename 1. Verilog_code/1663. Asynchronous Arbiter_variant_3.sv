//SystemVerilog
module async_arbiter #(parameter WIDTH = 4) (
  input [WIDTH-1:0] req,
  output [WIDTH-1:0] gnt
);
  wire [WIDTH-1:0] req_mask;
  
  assign req_mask[0] = 1'b1;
  genvar i;
  generate
    for (i = 1; i < WIDTH; i = i + 1) begin: gen_mask
      assign req_mask[i] = req_mask[i-1] & ~req[i-1];
    end
  endgenerate
  
  assign gnt = req & req_mask;
endmodule