module lut_mult (
    input [3:0] a, b,
    output reg [7:0] product
);
    always @(*) begin
        case({a, b})
            8'h00: product = 8'h00; // 0 * 0 = 0
            8'h01: product = 8'h00; // 0 * 1 = 0
            8'h02: product = 8'h00; // 0 * 2 = 0
            8'h03: product = 8'h00; // 0 * 3 = 0
            8'h04: product = 8'h00; // 0 * 4 = 0
            8'h05: product = 8'h00; // 0 * 5 = 0
            8'h06: product = 8'h00; // 0 * 6 = 0
            8'h07: product = 8'h00; // 0 * 7 = 0
            8'h08: product = 8'h00; // 0 * 8 = 0
            8'h09: product = 8'h00; // 0 * 9 = 0
            8'h0A: product = 8'h00; // 0 * 10 = 0
            8'h0B: product = 8'h00; // 0 * 11 = 0
            8'h0C: product = 8'h00; // 0 * 12 = 0
            8'h0D: product = 8'h00; // 0 * 13 = 0
            8'h0E: product = 8'h00; // 0 * 14 = 0
            8'h0F: product = 8'h00; // 0 * 15 = 0
            
            8'h10: product = 8'h00; // 1 * 0 = 0
            8'h11: product = 8'h01; // 1 * 1 = 1
            8'h12: product = 8'h02; // 1 * 2 = 2
            8'h13: product = 8'h03; // 1 * 3 = 3
            // 中间省略部分查找表
            
            8'hF0: product = 8'h00; // 15 * 0 = 0
            8'hF1: product = 8'h0F; // 15 * 1 = 15
            8'hF2: product = 8'h1E; // 15 * 2 = 30
            8'hF3: product = 8'h2D; // 15 * 3 = 45
            8'hF4: product = 8'h3C; // 15 * 4 = 60
            8'hF5: product = 8'h4B; // 15 * 5 = 75
            8'hF6: product = 8'h5A; // 15 * 6 = 90
            8'hF7: product = 8'h69; // 15 * 7 = 105
            8'hF8: product = 8'h78; // 15 * 8 = 120
            8'hF9: product = 8'h87; // 15 * 9 = 135
            8'hFA: product = 8'h96; // 15 * 10 = 150
            8'hFB: product = 8'hA5; // 15 * 11 = 165
            8'hFC: product = 8'hB4; // 15 * 12 = 180
            8'hFD: product = 8'hC3; // 15 * 13 = 195
            8'hFE: product = 8'hD2; // 15 * 14 = 210
            8'hFF: product = 8'hE1; // 15 * 15 = 225
            
            default: product = 8'h00;
        endcase
    end
endmodule