module Sub4(input clk, [7:0] d1,d2, output reg [7:0] out);
    always @(posedge clk) out <= d1 - d2;
endmodule