//SystemVerilog
module seg7_sync_decoder (
    input clk, rst_n, en,
    input [3:0] bcd,
    output reg [6:0] seg
);
    // IEEE 1364-2005 Verilog standard
    
    // Register to buffer the high fanout bcd signal
    reg [3:0] bcd_buf1, bcd_buf2;
    
    // First stage buffer for bcd signal
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            bcd_buf1 <= 4'h0;
        else
            bcd_buf1 <= bcd;
    end
    
    // Second stage buffer to further distribute fanout load
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            bcd_buf2 <= 4'h0;
        else
            bcd_buf2 <= bcd_buf1;
    end
    
    // Decoder logic with reduced fanout using buffered signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            seg <= 7'h7F;
        else if (en) begin
            case (bcd_buf2)
                4'd0: seg <= 7'h3F;
                4'd1: seg <= 7'h06;
                4'd2: seg <= 7'h5B;
                4'd3: seg <= 7'h4F;
                4'd4: seg <= 7'h66;
                4'd5: seg <= 7'h6D;
                4'd6: seg <= 7'h7D;
                4'd7: seg <= 7'h07;
                4'd8: seg <= 7'h7F;
                4'd9: seg <= 7'h6F;
                default: seg <= 7'h00;
            endcase
        end
    end
endmodule