//SystemVerilog
module divider_8bit (
    input [7:0] a,
    input [7:0] b,
    output [7:0] quotient,
    output [7:0] remainder
);

    wire [7:0] q;
    wire [7:0] r;

    arithmetic_unit u_arithmetic (
        .a(a),
        .b(b),
        .quotient(q),
        .remainder(r)
    );

    assign quotient = q;
    assign remainder = r;

endmodule

module arithmetic_unit (
    input [7:0] a,
    input [7:0] b,
    output reg [7:0] quotient,
    output reg [7:0] remainder
);

    wire b_zero;
    wire [7:0] div_result;
    wire [7:0] mod_result;

    assign b_zero = (b == 8'b0);
    
    // Division and modulo operations
    assign div_result = a / b;
    assign mod_result = a % b;

    always @(*) begin
        quotient = b_zero ? 8'b0 : div_result;
        remainder = b_zero ? a : mod_result;
    end

endmodule