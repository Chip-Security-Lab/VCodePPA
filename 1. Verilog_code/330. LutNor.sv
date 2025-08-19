module LutNor(input a, b, output y);
    reg [3:0] lut = 4'b1000; // 4种可能值的LUT
    assign y = lut[{a,b}];
endmodule