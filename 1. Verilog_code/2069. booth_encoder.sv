module booth_encoder #(parameter WIDTH = 4) (
    input wire [WIDTH:0] multiplier_bits,  // 3 adjacent bits
    output reg [1:0] booth_op,             // Operation: 00=0, 01=+A, 10=-A, 11=+2A
    output reg neg                         // Negate result
);
    always @(*) begin
        case (multiplier_bits)
            3'b000, 3'b111: begin booth_op = 2'b00; neg = 1'b0; end  // 0
            3'b001, 3'b010: begin booth_op = 2'b01; neg = 1'b0; end  // +A
            3'b101, 3'b110: begin booth_op = 2'b01; neg = 1'b1; end  // -A
            3'b011:         begin booth_op = 2'b11; neg = 1'b0; end  // +2A
            3'b100:         begin booth_op = 2'b11; neg = 1'b1; end  // -2A
            default:        begin booth_op = 2'b00; neg = 1'b0; end
        endcase
    end
endmodule