module Sub3 #(parameter W=4)(input [W-1:0] a,b, output [W-1:0] res);
    reg [W-1:0] lut [0:15];
    reg [W-1:0] diff;
    
    initial begin
        lut[0] = 4'b0000; lut[1] = 4'b1111; lut[2] = 4'b1110; lut[3] = 4'b1101;
        lut[4] = 4'b1100; lut[5] = 4'b1011; lut[6] = 4'b1010; lut[7] = 4'b1001;
        lut[8] = 4'b1000; lut[9] = 4'b0111; lut[10] = 4'b0110; lut[11] = 4'b0101;
        lut[12] = 4'b0100; lut[13] = 4'b0011; lut[14] = 4'b0010; lut[15] = 4'b0001;
    end
    
    always @(*) begin
        diff = lut[b] + a;
    end
    
    assign res = diff;
endmodule