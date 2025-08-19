module Div1(input [7:0] dividend, divisor, output [7:0] quotient);
    assign quotient = divisor ? dividend / divisor : 8'hFF;
endmodule