//SystemVerilog
module expr_tree #(parameter DW=8) (
    input  [DW-1:0] a,
    input  [DW-1:0] b,
    input  [DW-1:0] c,
    input  [1:0]    op,
    output reg [DW-1:0] out
);
    wire [1:0] a_sub_b_2bit;
    lut_subtractor_2bit u_lut_subtractor_2bit (
        .minuend(a[1:0]),
        .subtrahend(b[1:0]),
        .diff(a_sub_b_2bit)
    );

    wire [DW-1:0] sub_res;
    assign sub_res = { {(DW-2){1'b0}}, a_sub_b_2bit }; // Zero-extend to DW bits

    always @* begin
        case (op)
            2'b00: begin
                out = a + (b * c);
            end
            2'b01: begin
                out = (sub_res) << c;
            end
            2'b10: begin
                if (a > b) begin
                    out = c;
                end else begin
                    out = a;
                end
            end
            default: begin
                out = a ^ b ^ c;
            end
        endcase
    end
endmodule

module lut_subtractor_2bit (
    input  [1:0] minuend,
    input  [1:0] subtrahend,
    output reg [1:0] diff
);
    always @* begin
        case ({minuend, subtrahend})
            4'b0000: diff = 2'b00; // 0 - 0 = 0
            4'b0001: diff = 2'b11; // 0 - 1 = -1 (2'b11)
            4'b0010: diff = 2'b10; // 0 - 2 = -2 (2'b10)
            4'b0011: diff = 2'b01; // 0 - 3 = -3 (2'b01)
            4'b0100: diff = 2'b01; // 1 - 0 = 1
            4'b0101: diff = 2'b00; // 1 - 1 = 0
            4'b0110: diff = 2'b11; // 1 - 2 = -1 (2'b11)
            4'b0111: diff = 2'b10; // 1 - 3 = -2 (2'b10)
            4'b1000: diff = 2'b10; // 2 - 0 = 2
            4'b1001: diff = 2'b01; // 2 - 1 = 1
            4'b1010: diff = 2'b00; // 2 - 2 = 0
            4'b1011: diff = 2'b11; // 2 - 3 = -1 (2'b11)
            4'b1100: diff = 2'b11; // 3 - 0 = 3
            4'b1101: diff = 2'b10; // 3 - 1 = 2
            4'b1110: diff = 2'b01; // 3 - 2 = 1
            4'b1111: diff = 2'b00; // 3 - 3 = 0
            default: diff = 2'b00;
        endcase
    end
endmodule