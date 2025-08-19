module bcd_to_7seg(
    input [3:0] bcd,
    output reg [6:0] seg
);
    always @(*) begin
        case(bcd)  // 组合case语句
            0: seg = 7'b0111111;  // 0
            1: seg = 7'b0000110;  // 1
            2: seg = 7'b1011011;  // 2
            3: seg = 7'b1001111;  // 3
            4: seg = 7'b1100110;  // 4
            5: seg = 7'b1101101;  // 5
            6: seg = 7'b1111101;  // 6
            7: seg = 7'b0000111;  // 7
            8: seg = 7'b1111111;  // 8
            9: seg = 7'b1101111;  // 9
            default: seg = 7'b0000000;  // Turn off all segments for invalid BCD
        endcase
    end
endmodule