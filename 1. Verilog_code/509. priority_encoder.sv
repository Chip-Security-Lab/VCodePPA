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
            default:     code = 3'b000;
        endcase
    end
endmodule