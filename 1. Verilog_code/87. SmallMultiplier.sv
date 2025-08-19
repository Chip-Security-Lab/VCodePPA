module SmallMultiplier(
    input [1:0] a, b,
    output reg [3:0] prod
);
    always @(*) begin
        case({a, b})
            4'b0000: prod = 0;  // 0 * 0 = 0
            4'b0001: prod = 0;  // 0 * 1 = 0
            4'b0010: prod = 0;  // 0 * 2 = 0
            4'b0011: prod = 0;  // 0 * 3 = 0
            4'b0100: prod = 0;  // 1 * 0 = 0
            4'b0101: prod = 1;  // 1 * 1 = 1
            4'b0110: prod = 2;  // 1 * 2 = 2
            4'b0111: prod = 3;  // 1 * 3 = 3
            4'b1000: prod = 0;  // 2 * 0 = 0
            4'b1001: prod = 2;  // 2 * 1 = 2
            4'b1010: prod = 4;  // 2 * 2 = 4
            4'b1011: prod = 6;  // 2 * 3 = 6
            4'b1100: prod = 0;  // 3 * 0 = 0
            4'b1101: prod = 3;  // 3 * 1 = 3
            4'b1110: prod = 6;  // 3 * 2 = 6
            4'b1111: prod = 9;  // 3 * 3 = 9
        endcase
    end
endmodule