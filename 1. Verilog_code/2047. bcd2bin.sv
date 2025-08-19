module bcd2bin (
    input wire [11:0] bcd_in,  // 3 BCD digits
    output wire [9:0] bin_out  // Binary value up to 999
);
    wire [7:0] hundreds, tens, ones;
    assign hundreds = {4'b0, bcd_in[11:8]} * 8'd100;
    assign tens = {4'b0, bcd_in[7:4]} * 4'd10;
    assign ones = {4'b0, bcd_in[3:0]};
    assign bin_out = hundreds + tens + ones;
endmodule