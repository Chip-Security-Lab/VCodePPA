//SystemVerilog
module divider_4bit_with_overflow (
    input [3:0] a,
    input [3:0] b,
    output [3:0] quotient,
    output [3:0] remainder,
    output overflow
);

    wire [3:0] div_result;
    wire [3:0] mod_result;
    wire div_by_zero;

    // SRT division core
    srt_divider_core SRT_DIV (
        .a(a),
        .b(b),
        .div_result(div_result),
        .mod_result(mod_result)
    );

    // Zero detection submodule
    zero_detector ZERO_DET (
        .b(b),
        .div_by_zero(div_by_zero)
    );

    // Output control submodule
    output_control OUT_CTRL (
        .div_result(div_result),
        .mod_result(mod_result),
        .div_by_zero(div_by_zero),
        .quotient(quotient),
        .remainder(remainder),
        .overflow(overflow)
    );

endmodule

module srt_divider_core (
    input [3:0] a,
    input [3:0] b,
    output [3:0] div_result,
    output [3:0] mod_result
);

    reg [3:0] q;
    reg [3:0] r;
    reg [3:0] d;
    reg [3:0] q_next;
    reg [3:0] r_next;
    integer i;

    always @(*) begin
        q = 0;
        r = a;
        d = b;
        
        for(i = 0; i < 4; i = i + 1) begin
            if(r >= d) begin
                q_next = (q << 1) | 1'b1;
                r_next = r - d;
            end else begin
                q_next = q << 1;
                r_next = r;
            end
            q = q_next;
            r = r_next;
            d = d >> 1;
        end
    end

    assign div_result = q;
    assign mod_result = r;

endmodule

module zero_detector (
    input [3:0] b,
    output div_by_zero
);

    assign div_by_zero = (b == 4'b0000);

endmodule

module output_control (
    input [3:0] div_result,
    input [3:0] mod_result,
    input div_by_zero,
    output [3:0] quotient,
    output [3:0] remainder,
    output overflow
);

    assign quotient = div_by_zero ? 4'b0000 : div_result;
    assign remainder = div_by_zero ? 4'b0000 : mod_result;
    assign overflow = div_by_zero;

endmodule