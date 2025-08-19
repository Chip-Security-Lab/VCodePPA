module SeqSub(input clk, [3:0] in1,in2, output reg [3:0] diff);
    always @(posedge clk) diff <= (in1 > in2) ? in1 - in2 : in2 - in1;
endmodule