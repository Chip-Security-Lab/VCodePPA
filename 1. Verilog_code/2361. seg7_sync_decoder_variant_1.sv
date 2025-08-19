//SystemVerilog
module seg7_sync_decoder (
    input clk, rst_n, en,
    input [3:0] bcd,
    output reg [6:0] seg
);
    // 转换成条件运算符结构
    always @(posedge clk or negedge rst_n) begin
        seg <= (!rst_n) ? 7'h7F :
               (en) ? (
                   (bcd == 4'd0) ? 7'h3F :
                   (bcd == 4'd1) ? 7'h06 :
                   (bcd == 4'd2) ? 7'h5B :
                   (bcd == 4'd3) ? 7'h4F :
                   (bcd == 4'd4) ? 7'h66 :
                   (bcd == 4'd5) ? 7'h6D :
                   (bcd == 4'd6) ? 7'h7D :
                   (bcd == 4'd7) ? 7'h07 :
                   (bcd == 4'd8) ? 7'h7F :
                   (bcd == 4'd9) ? 7'h6F :
                   7'h00
               ) : seg;
    end
endmodule