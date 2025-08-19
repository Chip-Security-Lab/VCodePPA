//SystemVerilog

//-----------------------------
// Digit Decoder Submodule
// Decodes 4-bit binary input into a digit select signal
//-----------------------------
module bin_digit_decoder (
    input  wire [3:0] bin_in,
    output reg  [4:0] digit_sel  // One-hot encoding for 0-4, [4]=others
);
    always @(*) begin
        digit_sel = 5'b00000;
        case (bin_in)
            4'h0: digit_sel = 5'b00001;
            4'h1: digit_sel = 5'b00010;
            4'h2: digit_sel = 5'b00100;
            4'h3: digit_sel = 5'b01000;
            4'h4: digit_sel = 5'b10000;
            default: digit_sel = 5'b00000;
        endcase
    end
endmodule

//-----------------------------
// Seven Segment Encoder Submodule
// Encodes one-hot digit_sel into 7-segment active-low output
//-----------------------------
module sevenseg_encoder (
    input  wire [4:0] digit_sel, // One-hot: [0]=0, [1]=1, [2]=2, [3]=3, [4]=4, else blank
    output reg  [6:0] seg_out_n  // active low {a,b,c,d,e,f,g}
);
    always @(*) begin
        case (digit_sel)
            5'b00001: seg_out_n = 7'b0000001; // 0
            5'b00010: seg_out_n = 7'b1001111; // 1
            5'b00100: seg_out_n = 7'b0010010; // 2
            5'b01000: seg_out_n = 7'b0000110; // 3
            5'b10000: seg_out_n = 7'b1001100; // 4
            default:  seg_out_n = 7'b1111111; // blank
        endcase
    end
endmodule

//-----------------------------
// Top-Level Module: bin2sevenseg
// Hierarchically connects digit decoder and segment encoder
//-----------------------------
module bin2sevenseg (
    input  wire [3:0] bin_in,
    output wire [6:0] seg_out_n
);

    wire [4:0] digit_sel;

    // Digit decoder instance
    bin_digit_decoder u_digit_decoder (
        .bin_in    (bin_in),
        .digit_sel (digit_sel)
    );

    // Seven segment encoder instance
    sevenseg_encoder u_sevenseg_encoder (
        .digit_sel (digit_sel),
        .seg_out_n (seg_out_n)
    );

endmodule