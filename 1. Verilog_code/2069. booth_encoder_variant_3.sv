//SystemVerilog
// booth_encoder.v (Top Level)
module booth_encoder #(parameter WIDTH = 4) (
    input  wire [WIDTH:0] multiplier_bits,
    output wire [1:0]     booth_op,
    output wire           neg
);
    wire [2:0] selected_bits;
    assign selected_bits = multiplier_bits[2:0];

    wire [1:0] decoded_op;
    wire       decoded_negate;

    booth_op_decoder booth_op_decoder_inst (
        .bits   (selected_bits),
        .op     (decoded_op),
        .negate (decoded_negate)
    );

    assign booth_op = decoded_op;
    assign neg      = decoded_negate;
endmodule

// booth_op_decoder.v
module booth_op_decoder (
    input  wire [2:0] bits,
    output wire [1:0] op,
    output wire       negate
);

    reg [1:0] op_reg;
    reg       negate_reg;

    // Independent always block for op_reg
    always @(*) begin
        case (bits)
            3'b000, 3'b111: op_reg = 2'b00; // 0
            3'b001, 3'b010: op_reg = 2'b01; // +A
            3'b101, 3'b110: op_reg = 2'b01; // -A
            3'b011:         op_reg = 2'b11; // +2A
            3'b100:         op_reg = 2'b11; // -2A
            default:        op_reg = 2'b00;
        endcase
    end

    // Independent always block for negate_reg
    always @(*) begin
        case (bits)
            3'b000, 3'b111: negate_reg = 1'b0; // 0
            3'b001, 3'b010: negate_reg = 1'b0; // +A
            3'b101, 3'b110: negate_reg = 1'b1; // -A
            3'b011:         negate_reg = 1'b0; // +2A
            3'b100:         negate_reg = 1'b1; // -2A
            default:        negate_reg = 1'b0;
        endcase
    end

    assign op     = op_reg;
    assign negate = negate_reg;

endmodule