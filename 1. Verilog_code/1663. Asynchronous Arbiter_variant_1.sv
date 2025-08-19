//SystemVerilog
module async_arbiter #(parameter WIDTH = 4) (
  input [WIDTH-1:0] req,
  output [WIDTH-1:0] gnt
);
  wire [WIDTH-1:0] mask;
  
  // 生成掩码信号
  genvar i;
  generate
    for (i = 0; i < WIDTH; i = i + 1) begin: gen_mask
      if (i == 0)
        assign mask[i] = 1'b1;
      else
        assign mask[i] = ~|req[i-1:0];
    end
  endgenerate
  
  // 生成授权信号
  assign gnt = req & mask;
endmodule