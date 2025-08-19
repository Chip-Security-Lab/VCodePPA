//SystemVerilog

module bin2sevenseg (
    input wire [3:0] bin_in,
    output reg [6:0] seg_out_n  // active low {a,b,c,d,e,f,g}
);

    wire [6:0] mul_result;
    reg [6:0] mul_a, mul_b;
    reg [13:0] shift_accum;
    integer i;

    // 例：仅在 bin_in = 2,3,4 时用乘法器生成段码
    always @(*) begin
        case (bin_in)
            4'h0: seg_out_n = 7'b0000001;  // 0
            4'h1: seg_out_n = 7'b1001111;  // 1
            4'h2: begin
                // 用移位累加法实现 2 * 7'b0001001
                mul_a = 7'b0000010;   // 2
                mul_b = 7'b0001001;   // 7'b0010010 = 2 * 7'b0001001
                shift_accum = 14'b0;
                for (i = 0; i < 7; i = i + 1) begin
                    if (mul_b[i])
                        shift_accum = shift_accum + (mul_a << i);
                end
                seg_out_n = shift_accum[6:0];
            end
            4'h3: begin
                // 用移位累加法实现 3 * 7'b0000010
                mul_a = 7'b0000011;   // 3
                mul_b = 7'b0000010;   // 2
                shift_accum = 14'b0;
                for (i = 0; i < 7; i = i + 1) begin
                    if (mul_b[i])
                        shift_accum = shift_accum + (mul_a << i);
                end
                // 7'b0000110 = 3 * 2
                seg_out_n = shift_accum[6:0];
            end
            4'h4: begin
                // 用移位累加法实现 4 * 7'b0011001
                mul_a = 7'b0000100;   // 4
                mul_b = 7'b0011001;   // 25
                shift_accum = 14'b0;
                for (i = 0; i < 7; i = i + 1) begin
                    if (mul_b[i])
                        shift_accum = shift_accum + (mul_a << i);
                end
                // seg_out_n = 4 * 25
                seg_out_n = shift_accum[6:0];
            end
            default: seg_out_n = 7'b1111111;  // blank
        endcase
    end

endmodule