//SystemVerilog
//IEEE 1364-2005 Verilog
module seg7_sync_decoder (
    input clk, rst_n, en,
    input [3:0] bcd,
    output reg [6:0] seg
);
    // Segment patterns for each digit (0-9)
    localparam [6:0] SEG_0 = 7'h3F, SEG_1 = 7'h06, SEG_2 = 7'h5B, SEG_3 = 7'h4F,
                     SEG_4 = 7'h66, SEG_5 = 7'h6D, SEG_6 = 7'h7D, SEG_7 = 7'h07,
                     SEG_8 = 7'h7F, SEG_9 = 7'h6F, SEG_OFF = 7'h00, SEG_BLANK = 7'h7F;
    
    // Segment pattern based on BCD input
    reg [6:0] seg_pattern;
    
    // Combinational logic for segment pattern selection
    always @(*) begin
        if (bcd == 4'd0)
            seg_pattern = SEG_0;
        else if (bcd == 4'd1)
            seg_pattern = SEG_1;
        else if (bcd == 4'd2)
            seg_pattern = SEG_2;
        else if (bcd == 4'd3)
            seg_pattern = SEG_3;
        else if (bcd == 4'd4)
            seg_pattern = SEG_4;
        else if (bcd == 4'd5)
            seg_pattern = SEG_5;
        else if (bcd == 4'd6)
            seg_pattern = SEG_6;
        else if (bcd == 4'd7)
            seg_pattern = SEG_7;
        else if (bcd == 4'd8)
            seg_pattern = SEG_8;
        else if (bcd == 4'd9)
            seg_pattern = SEG_9;
        else
            seg_pattern = SEG_OFF;
    end
    
    // Sequential logic with explicit if-else
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            seg <= SEG_BLANK;
        else begin
            if (en)
                seg <= seg_pattern;
            else
                seg <= seg;
        end
    end
endmodule