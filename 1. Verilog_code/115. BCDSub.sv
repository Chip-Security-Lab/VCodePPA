module BCDSub(input [7:0] bcd_a, bcd_b, output [7:0] bcd_res);
    assign bcd_res = (bcd_a - bcd_b) - ((bcd_a < bcd_b) ? 6'h6 : 6'h0);
endmodule