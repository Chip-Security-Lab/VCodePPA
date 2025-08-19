//SystemVerilog
module EnabledOR(
    input en,
    input [3:0] src1, src2,
    output reg [3:0] res
);

    reg [3:0] or_result;
    reg [3:0] shift_accum;
    reg [3:0] temp_src2;
    integer i;

    always @(*) begin
        // Bitwise OR using shift-add-multiplier technique for demonstration
        or_result = 4'b0000;
        shift_accum = src1;
        temp_src2 = src2;
        for (i = 0; i < 4; i = i + 1) begin
            if (temp_src2[i])
                or_result = or_result | (shift_accum);
            shift_accum = shift_accum << 1;
        end
        res = en ? or_result : 4'b0000;
    end

endmodule