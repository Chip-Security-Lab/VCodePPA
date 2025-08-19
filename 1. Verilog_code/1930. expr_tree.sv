module expr_tree #(parameter DW=8) (
    input [DW-1:0] a, b, c,
    input [1:0] op,
    output reg [DW-1:0] out
);
    always @* begin
        case(op)
            2'b00: out = a + (b * c);
            2'b01: out = (a - b) << c;
            2'b10: out = a > b ? c : a;
            default: out = a ^ b ^ c;
        endcase
    end
endmodule
