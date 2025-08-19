module binary_to_decimal_ascii #(parameter WIDTH=8)(
    input wire [WIDTH-1:0] binary_in,
    output reg [8*3-1:0] ascii_out // 最多3位十进制数的ASCII
);
    reg [3:0] hundreds, tens, ones;
    
    always @* begin
        hundreds = binary_in / 100;
        tens = (binary_in / 10) % 10;
        ones = binary_in % 10;
        
        ascii_out[23:16] = hundreds ? (8'h30 + hundreds) : 8'h20; // 空格或数字
        ascii_out[15:8] = (hundreds || tens) ? (8'h30 + tens) : 8'h20; // 空格或数字
        ascii_out[7:0] = 8'h30 + ones; // 始终显示个位数
    end
endmodule