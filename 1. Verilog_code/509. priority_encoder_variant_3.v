module priority_encoder(
    input [7:0] req,
    output reg [2:0] code
);
    always @(*) begin
        casex(req)
            8'b1xxxxxxx: code = 3'b111;
            8'b01xxxxxx: code = 3'b110;
            8'b001xxxxx: code = 3'b101;
            8'b0001xxxx: code = 3'b100;
            8'b00001xxx: code = 3'b011;
            8'b000001xx: code = 3'b010;
            8'b0000001x: code = 3'b001;
            8'b00000001: code = 3'b000;
            default:     code = 3'b000;
        endcase
    end
endmodule