//SystemVerilog
module async_arbiter #(parameter WIDTH = 4) (
  input [WIDTH-1:0] req,
  output [WIDTH-1:0] gnt
);

  wire [WIDTH-1:0] borrow;
  wire [WIDTH-1:0] diff;
  
  // 3-bit borrow subtractor implementation
  assign borrow[0] = 1'b0;
  assign diff[0] = req[0];
  
  assign borrow[1] = ~req[0];
  assign diff[1] = req[1] & ~req[0];
  
  assign borrow[2] = ~(|req[1:0]);
  assign diff[2] = req[2] & ~(|req[1:0]);
  
  assign borrow[3] = ~(|req[2:0]);
  assign diff[3] = req[3] & ~(|req[2:0]);
  
  assign gnt = diff;

endmodule