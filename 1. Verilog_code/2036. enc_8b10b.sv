module enc_8b10b (
    input [7:0] data_in,
    output reg [9:0] encoded
);
    always @* begin
        case(data_in)
            8'h00: encoded = 10'b100111_0100;  // 示例编码
            8'h01: encoded = 10'b011101_0100;
            default: encoded = 10'b000000_0000;
        endcase
    end
endmodule