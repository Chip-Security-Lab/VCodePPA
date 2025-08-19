module binary_to_bcd #(parameter WIDTH=8, DIGITS=3)(
    input wire [WIDTH-1:0] binary_in,
    output reg [4*DIGITS-1:0] bcd_out
);
    integer i, j;
    reg [4*DIGITS-1:0] bcd;
    reg [WIDTH-1:0] bin;
    
    always @* begin
        bcd = 0;
        bin = binary_in;
        for (i = 0; i < WIDTH; i = i + 1) begin
            // 加3检查调整
            for (j = 0; j < DIGITS; j = j + 1) begin
                if (bcd[4*j+:4] > 4) bcd[4*j+:4] = bcd[4*j+:4] + 3;
            end
            // 左移所有位
            bcd = bcd << 1;
            bcd[0] = bin[WIDTH-1];
            bin = bin << 1;
        end
        bcd_out = bcd;
    end
endmodule