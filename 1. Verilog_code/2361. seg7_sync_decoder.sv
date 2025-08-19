module seg7_sync_decoder (
    input clk, rst_n, en,
    input [3:0] bcd,
    output reg [6:0] seg
);
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) seg <= 7'h7F;
    else if (en) case(bcd)
        0: seg <= 7'h3F; 1: seg <= 7'h06;
        2: seg <= 7'h5B; 3: seg <= 7'h4F;
        4: seg <= 7'h66; 5: seg <= 7'h6D;
        6: seg <= 7'h7D; 7: seg <= 7'h07;
        8: seg <= 7'h7F; 9: seg <= 7'h6F;
        default: seg <= 7'h00;
    endcase
end
endmodule
