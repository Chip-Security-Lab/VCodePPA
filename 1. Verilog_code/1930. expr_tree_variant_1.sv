//SystemVerilog
module expr_tree #(parameter DW=8) (
    input  wire [DW-1:0] a,
    input  wire [DW-1:0] b,
    input  wire [DW-1:0] c,
    input  wire [1:0]    op,
    output reg  [DW-1:0] out
);

    // Barrel shifter for (a - b) << c
    function [DW-1:0] barrel_left_shift;
        input [DW-1:0] data_in;
        input [DW-1:0] shift_amt;
        integer i;
        reg [DW-1:0] s [0:$clog2(DW)];
        begin
            s[0] = data_in;
            for (i = 0; i < $clog2(DW); i = i + 1) begin
                if (DW > (1 << i)) begin
                    if (shift_amt[i])
                        s[i+1] = s[i] << (1 << i);
                    else
                        s[i+1] = s[i];
                end else begin
                    s[i+1] = s[i];
                end
            end
            barrel_left_shift = s[$clog2(DW)];
        end
    endfunction

    wire [DW-1:0] add_mul_result;
    wire [DW-1:0] sub_result;
    wire [DW-1:0] shift_result;
    reg  [DW-1:0] cmp_result;
    wire [DW-1:0] xor_result;

    assign add_mul_result = a + (b * c);
    assign sub_result     = a - b;
    assign shift_result   = barrel_left_shift(sub_result, c);
    assign xor_result     = a ^ b ^ c;

    always @* begin
        if (a > b)
            cmp_result = c;
        else
            cmp_result = a;
    end

    always @* begin
        case(op)
            2'b00: out = add_mul_result;
            2'b01: out = shift_result;
            2'b10: out = cmp_result;
            default: out = xor_result;
        endcase
    end

endmodule