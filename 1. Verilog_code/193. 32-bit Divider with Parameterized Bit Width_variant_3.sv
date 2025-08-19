//SystemVerilog
// Top-level module
module divider_param #(parameter WIDTH=8)(
    input [WIDTH-1:0] dividend,
    input [WIDTH-1:0] divisor,
    output [WIDTH-1:0] quotient,
    output [WIDTH-1:0] remainder
);

    // Internal signals
    wire [WIDTH-1:0] shifted_dividend;
    wire [WIDTH-1:0] shifted_quotient;
    wire [WIDTH-1:0] next_dividend;
    wire [WIDTH-1:0] next_quotient;
    wire [WIDTH-1:0] final_quotient;
    wire [WIDTH-1:0] final_remainder;

    // Shift control module
    shift_control #(.WIDTH(WIDTH)) shift_ctrl (
        .dividend(dividend),
        .quotient(quotient),
        .divisor(divisor),
        .shifted_dividend(shifted_dividend),
        .shifted_quotient(shifted_quotient)
    );

    // Division operation module
    division_operation #(.WIDTH(WIDTH)) div_op (
        .shifted_dividend(shifted_dividend),
        .shifted_quotient(shifted_quotient),
        .divisor(divisor),
        .next_dividend(next_dividend),
        .next_quotient(next_quotient)
    );

    // Result generation module
    result_gen #(.WIDTH(WIDTH)) result (
        .next_dividend(next_dividend),
        .next_quotient(next_quotient),
        .final_quotient(final_quotient),
        .final_remainder(final_remainder)
    );

    // Output assignments
    assign quotient = final_quotient;
    assign remainder = final_remainder;

endmodule

// Shift control module
module shift_control #(parameter WIDTH=8)(
    input [WIDTH-1:0] dividend,
    input [WIDTH-1:0] quotient,
    input [WIDTH-1:0] divisor,
    output reg [WIDTH-1:0] shifted_dividend,
    output reg [WIDTH-1:0] shifted_quotient
);

    always @(*) begin
        shifted_dividend = dividend << 1;
        shifted_quotient = quotient << 1;
    end

endmodule

// Division operation module
module division_operation #(parameter WIDTH=8)(
    input [WIDTH-1:0] shifted_dividend,
    input [WIDTH-1:0] shifted_quotient,
    input [WIDTH-1:0] divisor,
    output reg [WIDTH-1:0] next_dividend,
    output reg [WIDTH-1:0] next_quotient
);

    always @(*) begin
        if (shifted_dividend >= divisor) begin
            next_dividend = shifted_dividend - divisor;
            next_quotient = shifted_quotient | 1'b1;
        end else begin
            next_dividend = shifted_dividend;
            next_quotient = shifted_quotient;
        end
    end

endmodule

// Result generation module
module result_gen #(parameter WIDTH=8)(
    input [WIDTH-1:0] next_dividend,
    input [WIDTH-1:0] next_quotient,
    output reg [WIDTH-1:0] final_quotient,
    output reg [WIDTH-1:0] final_remainder
);

    always @(*) begin
        final_quotient = next_quotient;
        final_remainder = next_dividend;
    end

endmodule