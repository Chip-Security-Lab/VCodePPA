//SystemVerilog
module adaptive_quant(
    input  wire [31:0] f,
    input  wire [7:0]  bits,
    output reg  [31:0] q
);
    reg [31:0] scale;
    reg [63:0] temp;
    wire       is_positive;
    wire       overflow_pos;
    wire       overflow_neg;

    assign is_positive  = ~f[31];
    assign overflow_pos = is_positive && (temp[63:31] != 33'd0);
    assign overflow_neg = ~is_positive && (temp[63:31] != {33{1'b1}});
    
    always @(*) begin
        scale = 32'd1 << bits;
        temp  = f * scale;

        case (1'b1)
            overflow_pos: q = 32'h7FFFFFFF;
            overflow_neg: q = 32'h80000000;
            default:      q = temp[31:0];
        endcase
    end
endmodule