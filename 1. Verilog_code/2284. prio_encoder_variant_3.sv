//SystemVerilog
module prio_encoder (
    input [7:0] req,
    output reg [2:0] code
);
    // 合并优先编码逻辑，减少always块和中间信号
    always @(*) begin
        casez(req)
            8'b1???????: code = 3'b111;
            8'b01??????: code = 3'b110;
            8'b001?????: code = 3'b101;
            8'b0001????: code = 3'b100;
            8'b00001???: code = 3'b011;
            8'b000001??: code = 3'b010;
            8'b0000001?: code = 3'b001;
            8'b00000001: code = 3'b000;
            default:     code = 3'b000;
        endcase
    end
endmodule