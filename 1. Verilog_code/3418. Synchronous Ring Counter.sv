module RD8 #(parameter SIZE=4)(
  input clk, input rst,
  output reg [SIZE-1:0] ring
);
always @(posedge clk) begin
  if (rst) ring <= 'b1;
  else     ring <= {ring[SIZE-2:0], ring[SIZE-1]};
end
endmodule
