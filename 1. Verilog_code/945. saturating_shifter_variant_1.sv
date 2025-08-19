//SystemVerilog
module saturating_shifter (
    input [7:0] din,
    input [2:0] shift,
    output reg [7:0] dout
);
    // 使用if-else级联结构替代case语句
    always @* begin
        if (shift == 3'd0) begin
            dout = din;
        end
        else if (shift == 3'd1) begin
            dout = din << 1;
        end
        else if (shift == 3'd2) begin
            dout = din << 2;
        end
        else if (shift == 3'd3) begin
            dout = din << 3;
        end
        else if (shift == 3'd4) begin
            dout = din << 4;
        end
        else if (shift == 3'd5) begin
            dout = din << 5;
        end
        else begin
            dout = 8'hFF;  // 所有大于5的移位都饱和到0xFF
        end
    end
endmodule