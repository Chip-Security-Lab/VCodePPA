module prio_enc_lut #(parameter DEPTH=8)(
  input [DEPTH-1:0] in,
  output reg [$clog2(DEPTH)-1:0] out
);
always @(*) begin
  out = 0;
  if (DEPTH == 8) begin
    casez(in)
      8'b1???_????: out = 3'd7;
      8'b01??_????: out = 3'd6;
      8'b001?_????: out = 3'd5;
      8'b0001_????: out = 3'd4;
      8'b0000_1???: out = 3'd3;
      8'b0000_01??: out = 3'd2;
      8'b0000_001?: out = 3'd1;
      default: out = 3'd0;
    endcase
  end
  else begin
    // 通用方法，适用于任何DEPTH值
    integer i;
    for(i=DEPTH-1; i>=0; i=i-1)
      if(in[i]) out = i[$clog2(DEPTH)-1:0];
  end
end
endmodule