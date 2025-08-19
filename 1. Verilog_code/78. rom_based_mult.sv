module rom_based_mult (
    input [3:0] addr_a,
    input [3:0] addr_b,
    output reg [7:0] product
);
    // ROM implementation using always block for lookup table
    always @(*) begin
        case ({addr_a, addr_b})
            // When addr_a = 0
            8'h00: product = 8'h00;  // 0 * 0 = 0
            8'h01: product = 8'h00;  // 0 * 1 = 0
            8'h02: product = 8'h00;  // 0 * 2 = 0
            8'h03: product = 8'h00;  // 0 * 3 = 0
            8'h04: product = 8'h00;  // 0 * 4 = 0
            8'h05: product = 8'h00;  // 0 * 5 = 0
            8'h06: product = 8'h00;  // 0 * 6 = 0
            8'h07: product = 8'h00;  // 0 * 7 = 0
            8'h08: product = 8'h00;  // 0 * 8 = 0
            8'h09: product = 8'h00;  // 0 * 9 = 0
            8'h0A: product = 8'h00;  // 0 * 10 = 0
            8'h0B: product = 8'h00;  // 0 * 11 = 0
            8'h0C: product = 8'h00;  // 0 * 12 = 0
            8'h0D: product = 8'h00;  // 0 * 13 = 0
            8'h0E: product = 8'h00;  // 0 * 14 = 0
            8'h0F: product = 8'h00;  // 0 * 15 = 0
            
            // When addr_a = 1
            8'h10: product = 8'h00;  // 1 * 0 = 0
            8'h11: product = 8'h01;  // 1 * 1 = 1
            8'h12: product = 8'h02;  // 1 * 2 = 2
            8'h13: product = 8'h03;  // 1 * 3 = 3
            8'h14: product = 8'h04;  // 1 * 4 = 4
            8'h15: product = 8'h05;  // 1 * 5 = 5
            8'h16: product = 8'h06;  // 1 * 6 = 6
            8'h17: product = 8'h07;  // 1 * 7 = 7
            8'h18: product = 8'h08;  // 1 * 8 = 8
            8'h19: product = 8'h09;  // 1 * 9 = 9
            8'h1A: product = 8'h0A;  // 1 * 10 = 10
            8'h1B: product = 8'h0B;  // 1 * 11 = 11
            8'h1C: product = 8'h0C;  // 1 * 12 = 12
            8'h1D: product = 8'h0D;  // 1 * 13 = 13
            8'h1E: product = 8'h0E;  // 1 * 14 = 14
            8'h1F: product = 8'h0F;  // 1 * 15 = 15
            
            // When addr_a = 2
            8'h20: product = 8'h00;  // 2 * 0 = 0
            8'h21: product = 8'h02;  // 2 * 1 = 2
            8'h22: product = 8'h04;  // 2 * 2 = 4
            8'h23: product = 8'h06;  // 2 * 3 = 6
            8'h24: product = 8'h08;  // 2 * 4 = 8
            8'h25: product = 8'h0A;  // 2 * 5 = 10
            8'h26: product = 8'h0C;  // 2 * 6 = 12
            8'h27: product = 8'h0E;  // 2 * 7 = 14
            8'h28: product = 8'h10;  // 2 * 8 = 16
            8'h29: product = 8'h12;  // 2 * 9 = 18
            8'h2A: product = 8'h14;  // 2 * 10 = 20
            8'h2B: product = 8'h16;  // 2 * 11 = 22
            8'h2C: product = 8'h18;  // 2 * 12 = 24
            8'h2D: product = 8'h1A;  // 2 * 13 = 26
            8'h2E: product = 8'h1C;  // 2 * 14 = 28
            8'h2F: product = 8'h1E;  // 2 * 15 = 30
            
            // When addr_a = 3
            8'h30: product = 8'h00;  // 3 * 0 = 0
            8'h31: product = 8'h03;  // 3 * 1 = 3
            8'h32: product = 8'h06;  // 3 * 2 = 6
            8'h33: product = 8'h09;  // 3 * 3 = 9
            8'h34: product = 8'h0C;  // 3 * 4 = 12
            8'h35: product = 8'h0F;  // 3 * 5 = 15
            8'h36: product = 8'h12;  // 3 * 6 = 18
            8'h37: product = 8'h15;  // 3 * 7 = 21
            8'h38: product = 8'h18;  // 3 * 8 = 24
            8'h39: product = 8'h1B;  // 3 * 9 = 27
            8'h3A: product = 8'h1E;  // 3 * 10 = 30
            8'h3B: product = 8'h21;  // 3 * 11 = 33
            8'h3C: product = 8'h24;  // 3 * 12 = 36
            8'h3D: product = 8'h27;  // 3 * 13 = 39
            8'h3E: product = 8'h2A;  // 3 * 14 = 42
            8'h3F: product = 8'h2D;  // 3 * 15 = 45
            
            // When addr_a = 4
            8'h40: product = 8'h00;  // 4 * 0 = 0
            8'h41: product = 8'h04;  // 4 * 1 = 4
            8'h42: product = 8'h08;  // 4 * 2 = 8
            8'h43: product = 8'h0C;  // 4 * 3 = 12
            8'h44: product = 8'h10;  // 4 * 4 = 16
            8'h45: product = 8'h14;  // 4 * 5 = 20
            8'h46: product = 8'h18;  // 4 * 6 = 24
            8'h47: product = 8'h1C;  // 4 * 7 = 28
            8'h48: product = 8'h20;  // 4 * 8 = 32
            8'h49: product = 8'h24;  // 4 * 9 = 36
            8'h4A: product = 8'h28;  // 4 * 10 = 40
            8'h4B: product = 8'h2C;  // 4 * 11 = 44
            8'h4C: product = 8'h30;  // 4 * 12 = 48
            8'h4D: product = 8'h34;  // 4 * 13 = 52
            8'h4E: product = 8'h38;  // 4 * 14 = 56
            8'h4F: product = 8'h3C;  // 4 * 15 = 60
            
            // When addr_a = 5
            8'h50: product = 8'h00;  // 5 * 0 = 0
            8'h51: product = 8'h05;  // 5 * 1 = 5
            8'h52: product = 8'h0A;  // 5 * 2 = 10
            8'h53: product = 8'h0F;  // 5 * 3 = 15
            8'h54: product = 8'h14;  // 5 * 4 = 20
            8'h55: product = 8'h19;  // 5 * 5 = 25
            8'h56: product = 8'h1E;  // 5 * 6 = 30
            8'h57: product = 8'h23;  // 5 * 7 = 35
            8'h58: product = 8'h28;  // 5 * 8 = 40
            8'h59: product = 8'h2D;  // 5 * 9 = 45
            8'h5A: product = 8'h32;  // 5 * 10 = 50
            8'h5B: product = 8'h37;  // 5 * 11 = 55
            8'h5C: product = 8'h3C;  // 5 * 12 = 60
            8'h5D: product = 8'h41;  // 5 * 13 = 65
            8'h5E: product = 8'h46;  // 5 * 14 = 70
            8'h5F: product = 8'h4B;  // 5 * 15 = 75
            
            // When addr_a = 6
            8'h60: product = 8'h00;  // 6 * 0 = 0
            8'h61: product = 8'h06;  // 6 * 1 = 6
            8'h62: product = 8'h0C;  // 6 * 2 = 12
            8'h63: product = 8'h12;  // 6 * 3 = 18
            8'h64: product = 8'h18;  // 6 * 4 = 24
            8'h65: product = 8'h1E;  // 6 * 5 = 30
            8'h66: product = 8'h24;  // 6 * 6 = 36
            8'h67: product = 8'h2A;  // 6 * 7 = 42
            8'h68: product = 8'h30;  // 6 * 8 = 48
            8'h69: product = 8'h36;  // 6 * 9 = 54
            8'h6A: product = 8'h3C;  // 6 * 10 = 60
            8'h6B: product = 8'h42;  // 6 * 11 = 66
            8'h6C: product = 8'h48;  // 6 * 12 = 72
            8'h6D: product = 8'h4E;  // 6 * 13 = 78
            8'h6E: product = 8'h54;  // 6 * 14 = 84
            8'h6F: product = 8'h5A;  // 6 * 15 = 90
            
            // When addr_a = 7
            8'h70: product = 8'h00;  // 7 * 0 = 0
            8'h71: product = 8'h07;  // 7 * 1 = 7
            8'h72: product = 8'h0E;  // 7 * 2 = 14
            8'h73: product = 8'h15;  // 7 * 3 = 21
            8'h74: product = 8'h1C;  // 7 * 4 = 28
            8'h75: product = 8'h23;  // 7 * 5 = 35
            8'h76: product = 8'h2A;  // 7 * 6 = 42
            8'h77: product = 8'h31;  // 7 * 7 = 49
            8'h78: product = 8'h38;  // 7 * 8 = 56
            8'h79: product = 8'h3F;  // 7 * 9 = 63
            8'h7A: product = 8'h46;  // 7 * 10 = 70
            8'h7B: product = 8'h4D;  // 7 * 11 = 77
            8'h7C: product = 8'h54;  // 7 * 12 = 84
            8'h7D: product = 8'h5B;  // 7 * 13 = 91
            8'h7E: product = 8'h62;  // 7 * 14 = 98
            8'h7F: product = 8'h69;  // 7 * 15 = 105
            
            // When addr_a = 8
            8'h80: product = 8'h00;  // 8 * 0 = 0
            8'h81: product = 8'h08;  // 8 * 1 = 8
            8'h82: product = 8'h10;  // 8 * 2 = 16
            8'h83: product = 8'h18;  // 8 * 3 = 24
            8'h84: product = 8'h20;  // 8 * 4 = 32
            8'h85: product = 8'h28;  // 8 * 5 = 40
            8'h86: product = 8'h30;  // 8 * 6 = 48
            8'h87: product = 8'h38;  // 8 * 7 = 56
            8'h88: product = 8'h40;  // 8 * 8 = 64
            8'h89: product = 8'h48;  // 8 * 9 = 72
            8'h8A: product = 8'h50;  // 8 * 10 = 80
            8'h8B: product = 8'h58;  // 8 * 11 = 88
            8'h8C: product = 8'h60;  // 8 * 12 = 96
            8'h8D: product = 8'h68;  // 8 * 13 = 104
            8'h8E: product = 8'h70;  // 8 * 14 = 112
            8'h8F: product = 8'h78;  // 8 * 15 = 120
            
            // When addr_a = 9
            8'h90: product = 8'h00;  // 9 * 0 = 0
            8'h91: product = 8'h09;  // 9 * 1 = 9
            8'h92: product = 8'h12;  // 9 * 2 = 18
            8'h93: product = 8'h1B;  // 9 * 3 = 27
            8'h94: product = 8'h24;  // 9 * 4 = 36
            8'h95: product = 8'h2D;  // 9 * 5 = 45
            8'h96: product = 8'h36;  // 9 * 6 = 54
            8'h97: product = 8'h3F;  // 9 * 7 = 63
            8'h98: product = 8'h48;  // 9 * 8 = 72
            8'h99: product = 8'h51;  // 9 * 9 = 81
            8'h9A: product = 8'h5A;  // 9 * 10 = 90
            8'h9B: product = 8'h63;  // 9 * 11 = 99
            8'h9C: product = 8'h6C;  // 9 * 12 = 108
            8'h9D: product = 8'h75;  // 9 * 13 = 117
            8'h9E: product = 8'h7E;  // 9 * 14 = 126
            8'h9F: product = 8'h87;  // 9 * 15 = 135
            
            // When addr_a = 10 (A)
            8'hA0: product = 8'h00;  // 10 * 0 = 0
            8'hA1: product = 8'h0A;  // 10 * 1 = 10
            8'hA2: product = 8'h14;  // 10 * 2 = 20
            8'hA3: product = 8'h1E;  // 10 * 3 = 30
            8'hA4: product = 8'h28;  // 10 * 4 = 40
            8'hA5: product = 8'h32;  // 10 * 5 = 50
            8'hA6: product = 8'h3C;  // 10 * 6 = 60
            8'hA7: product = 8'h46;  // 10 * 7 = 70
            8'hA8: product = 8'h50;  // 10 * 8 = 80
            8'hA9: product = 8'h5A;  // 10 * 9 = 90
            8'hAA: product = 8'h64;  // 10 * 10 = 100
            8'hAB: product = 8'h6E;  // 10 * 11 = 110
            8'hAC: product = 8'h78;  // 10 * 12 = 120
            8'hAD: product = 8'h82;  // 10 * 13 = 130
            8'hAE: product = 8'h8C;  // 10 * 14 = 140
            8'hAF: product = 8'h96;  // 10 * 15 = 150
            
            // When addr_a = 11 (B)
            8'hB0: product = 8'h00;  // 11 * 0 = 0
            8'hB1: product = 8'h0B;  // 11 * 1 = 11
            8'hB2: product = 8'h16;  // 11 * 2 = 22
            8'hB3: product = 8'h21;  // 11 * 3 = 33
            8'hB4: product = 8'h2C;  // 11 * 4 = 44
            8'hB5: product = 8'h37;  // 11 * 5 = 55
            8'hB6: product = 8'h42;  // 11 * 6 = 66
            8'hB7: product = 8'h4D;  // 11 * 7 = 77
            8'hB8: product = 8'h58;  // 11 * 8 = 88
            8'hB9: product = 8'h63;  // 11 * 9 = 99
            8'hBA: product = 8'h6E;  // 11 * 10 = 110
            8'hBB: product = 8'h79;  // 11 * 11 = 121
            8'hBC: product = 8'h84;  // 11 * 12 = 132
            8'hBD: product = 8'h8F;  // 11 * 13 = 143
            8'hBE: product = 8'h9A;  // 11 * 14 = 154
            8'hBF: product = 8'hA5;  // 11 * 15 = 165
            
            // When addr_a = 12 (C)
            8'hC0: product = 8'h00;  // 12 * 0 = 0
            8'hC1: product = 8'h0C;  // 12 * 1 = 12
            8'hC2: product = 8'h18;  // 12 * 2 = 24
            8'hC3: product = 8'h24;  // 12 * 3 = 36
            8'hC4: product = 8'h30;  // 12 * 4 = 48
            8'hC5: product = 8'h3C;  // 12 * 5 = 60
            8'hC6: product = 8'h48;  // 12 * 6 = 72
            8'hC7: product = 8'h54;  // 12 * 7 = 84
            8'hC8: product = 8'h60;  // 12 * 8 = 96
            8'hC9: product = 8'h6C;  // 12 * 9 = 108
            8'hCA: product = 8'h78;  // 12 * 10 = 120
            8'hCB: product = 8'h84;  // 12 * 11 = 132
            8'hCC: product = 8'h90;  // 12 * 12 = 144
            8'hCD: product = 8'h9C;  // 12 * 13 = 156
            8'hCE: product = 8'hA8;  // 12 * 14 = 168
            8'hCF: product = 8'hB4;  // 12 * 15 = 180
            
            // When addr_a = 13 (D)
            8'hD0: product = 8'h00;  // 13 * 0 = 0
            8'hD1: product = 8'h0D;  // 13 * 1 = 13
            8'hD2: product = 8'h1A;  // 13 * 2 = 26
            8'hD3: product = 8'h27;  // 13 * 3 = 39
            8'hD4: product = 8'h34;  // 13 * 4 = 52
            8'hD5: product = 8'h41;  // 13 * 5 = 65
            8'hD6: product = 8'h4E;  // 13 * 6 = 78
            8'hD7: product = 8'h5B;  // 13 * 7 = 91
            8'hD8: product = 8'h68;  // 13 * 8 = 104
            8'hD9: product = 8'h75;  // 13 * 9 = 117
            8'hDA: product = 8'h82;  // 13 * 10 = 130
            8'hDB: product = 8'h8F;  // 13 * 11 = 143
            8'hDC: product = 8'h9C;  // 13 * 12 = 156
            8'hDD: product = 8'hA9;  // 13 * 13 = 169
            8'hDE: product = 8'hB6;  // 13 * 14 = 182
            8'hDF: product = 8'hC3;  // 13 * 15 = 195
            
            // When addr_a = 14 (E)
            8'hE0: product = 8'h00;  // 14 * 0 = 0
            8'hE1: product = 8'h0E;  // 14 * 1 = 14
            8'hE2: product = 8'h1C;  // 14 * 2 = 28
            8'hE3: product = 8'h2A;  // 14 * 3 = 42
            8'hE4: product = 8'h38;  // 14 * 4 = 56
            8'hE5: product = 8'h46;  // 14 * 5 = 70
            8'hE6: product = 8'h54;  // 14 * 6 = 84
            8'hE7: product = 8'h62;  // 14 * 7 = 98
            8'hE8: product = 8'h70;  // 14 * 8 = 112
            8'hE9: product = 8'h7E;  // 14 * 9 = 126
            8'hEA: product = 8'h8C;  // 14 * 10 = 140
            8'hEB: product = 8'h9A;  // 14 * 11 = 154
            8'hEC: product = 8'hA8;  // 14 * 12 = 168
            8'hED: product = 8'hB6;  // 14 * 13 = 182
            8'hEE: product = 8'hC4;  // 14 * 14 = 196
            8'hEF: product = 8'hD2;  // 14 * 15 = 210
            
            // When addr_a = 15 (F)
            8'hF0: product = 8'h00;  // 15 * 0 = 0
            8'hF1: product = 8'h0F;  // 15 * 1 = 15
            8'hF2: product = 8'h1E;  // 15 * 2 = 30
            8'hF3: product = 8'h2D;  // 15 * 3 = 45
            8'hF4: product = 8'h3C;  // 15 * 4 = 60
            8'hF5: product = 8'h4B;  // 15 * 5 = 75
            8'hF6: product = 8'h5A;  // 15 * 6 = 90
            8'hF7: product = 8'h69;  // 15 * 7 = 105
            8'hF8: product = 8'h78;  // 15 * 8 = 120
            8'hF9: product = 8'h87;  // 15 * 9 = 135
            8'hFA: product = 8'h96;  // 15 * 10 = 150
            8'hFB: product = 8'hA5;  // 15 * 11 = 165
            8'hFC: product = 8'hB4;  // 15 * 12 = 180
            8'hFD: product = 8'hC3;  // 15 * 13 = 195
            8'hFE: product = 8'hD2;  // 15 * 14 = 210
            8'hFF: product = 8'hE1;  // 15 * 15 = 225
            
            // 真正的ROM实现不应该有default情况，但为了安全起见保留
            default: product = 8'h00;
        endcase
    end
endmodule