//SystemVerilog
module async_arbiter #(parameter WIDTH = 4) (
  input [WIDTH-1:0] req,
  output [WIDTH-1:0] gnt
);
  
  // Priority encoding using carry chain
  wire [WIDTH-1:0] gnt_next;
  assign gnt_next[0] = req[0];
  
  genvar i;
  generate
    for (i = 1; i < WIDTH; i = i + 1) begin: gen_priority
      assign gnt_next[i] = req[i] & ~(|req[i-1:0]);
    end
  endgenerate
  
  assign gnt = gnt_next;
  
endmodule