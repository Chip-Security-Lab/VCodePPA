module bcd2bin #(parameter N=4)(
    input [N*4-1:0] bcd,
    output [N*7-1:0] bin
);
genvar i;
generate for(i=0; i<N; i=i+1) begin
    assign bin[i*7+:7] = bcd[i*4+:4] * 10**i; 
end endgenerate
endmodule
