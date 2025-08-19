//SystemVerilog
module decoder_obfuscate #(parameter KEY=8'hA5) (
    input [7:0] cipher_addr,
    output reg [15:0] decoded
);
    wire [7:0] real_addr;
    wire [3:0] shift_amount;
    wire valid_shift;
    
    assign real_addr = cipher_addr ^ KEY;  // 简单异或解密
    assign shift_amount = real_addr[3:0];  // 移位量，最大为15
    assign valid_shift = (real_addr < 8'd16);
    
    // 桶形移位器实现
    always @(*) begin
        if (valid_shift) begin
            case (shift_amount)
                4'd0:  decoded = 16'b0000000000000001;
                4'd1:  decoded = 16'b0000000000000010;
                4'd2:  decoded = 16'b0000000000000100;
                4'd3:  decoded = 16'b0000000000001000;
                4'd4:  decoded = 16'b0000000000010000;
                4'd5:  decoded = 16'b0000000000100000;
                4'd6:  decoded = 16'b0000000001000000;
                4'd7:  decoded = 16'b0000000010000000;
                4'd8:  decoded = 16'b0000000100000000;
                4'd9:  decoded = 16'b0000001000000000;
                4'd10: decoded = 16'b0000010000000000;
                4'd11: decoded = 16'b0000100000000000;
                4'd12: decoded = 16'b0001000000000000;
                4'd13: decoded = 16'b0010000000000000;
                4'd14: decoded = 16'b0100000000000000;
                4'd15: decoded = 16'b1000000000000000;
            endcase
        end else begin
            decoded = 16'h0000;
        end
    end
endmodule