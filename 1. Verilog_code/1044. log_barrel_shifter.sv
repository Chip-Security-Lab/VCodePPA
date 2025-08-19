module log_barrel_shifter #(parameter WIDTH=32) (
  input [WIDTH-1:0] in_data,
  input [$clog2(WIDTH)-1:0] shift,
  output [WIDTH-1:0] out_data
);
  // Multi-stage logarithmic shifter implementation
  wire [WIDTH-1:0] stage [0:$clog2(WIDTH)];
  assign stage[0] = in_data;
  
  genvar i;
  generate
    for (i = 0; i < $clog2(WIDTH); i = i + 1) begin : shift_stages
      assign stage[i+1] = shift[i] ? stage[i] << (1 << i) : stage[i];
    end
  endgenerate
  
  assign out_data = stage[$clog2(WIDTH)];
endmodule