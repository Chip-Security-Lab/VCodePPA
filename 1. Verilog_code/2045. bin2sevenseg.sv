module bin2sevenseg (
    input wire [3:0] bin_in,
    output reg [6:0] seg_out_n  // active low {a,b,c,d,e,f,g}
);
    always @(*) begin
        case (bin_in)
            4'h0: seg_out_n = 7'b0000001;  // 0
            4'h1: seg_out_n = 7'b1001111;  // 1
            4'h2: seg_out_n = 7'b0010010;  // 2
            4'h3: seg_out_n = 7'b0000110;  // 3
            4'h4: seg_out_n = 7'b1001100;  // 4
            default: seg_out_n = 7'b1111111;  // blank
        endcase
    end
endmodule