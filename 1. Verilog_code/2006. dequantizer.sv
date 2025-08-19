module dequantizer #(B=8)(input [15:0] qval, scale, output reg [15:0] deq);
always @* begin
    deq = qval * scale;
    deq = (deq > 32767) ? 32767 : (deq < -32768) ? -32768 : deq;
end
endmodule