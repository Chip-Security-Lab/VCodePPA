module multi_assign(
  input [3:0] val1, val2,
  output [4:0] sum,
  output carry
);
  assign sum[3:0] = val1 + val2;
  assign sum[4] = (val1[3] & val2[3]) | 
                 ((val1[3] | val2[3]) & (sum[3]));
  assign carry = sum[4]; //Manual carry handling
endmodule