//SystemVerilog
module range_mapper #(
    parameter IN_MIN = 0,
    parameter IN_MAX = 1023,
    parameter OUT_MIN = 0,
    parameter OUT_MAX = 255
) (
    input  wire [$clog2(IN_MAX-IN_MIN+1)-1:0] in_val,
    output reg  [$clog2(OUT_MAX-OUT_MIN+1)-1:0] out_val
);
    localparam IN_RANGE  = IN_MAX - IN_MIN;
    localparam OUT_RANGE = OUT_MAX - OUT_MIN;

    wire [7:0] input_subtractor_result;
    wire       input_subtractor_borrow;

    // 8位补码加法减法器
    twos_complement_subtractor_8bit u_twos_complement_subtractor_8bit (
        .minuend    (in_val[7:0]),
        .subtrahend (IN_MIN[7:0]),
        .difference (input_subtractor_result),
        .borrow_out (input_subtractor_borrow)
    );

    always @* begin
        out_val = ((input_subtractor_result * OUT_RANGE) / IN_RANGE) + OUT_MIN;
    end

endmodule

module twos_complement_subtractor_8bit (
    input  wire [7:0] minuend,
    input  wire [7:0] subtrahend,
    output wire [7:0] difference,
    output wire       borrow_out
);
    wire [7:0] subtrahend_inverted;
    wire [8:0] sum_with_carry;

    assign subtrahend_inverted = ~subtrahend;
    assign sum_with_carry = {1'b0, minuend} + {1'b0, subtrahend_inverted} + 9'b1;
    assign difference = sum_with_carry[7:0];
    assign borrow_out = ~sum_with_carry[8]; // borrow_out = 1 表示有借位

endmodule