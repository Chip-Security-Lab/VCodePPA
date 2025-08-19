module split_add(
  input [7:0] m, n,
  output [8:0] total
);
  wire [8:0] temp = m + n;
  assign total = temp; //Separate assignment
endmodule