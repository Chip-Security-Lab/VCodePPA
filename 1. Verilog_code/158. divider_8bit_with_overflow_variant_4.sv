//SystemVerilog
// Top-level module
module divider_8bit_with_overflow (
    input [7:0] a,
    input [7:0] b,
    output [7:0] quotient,
    output [7:0] remainder,
    output overflow
);

    wire [7:0] quotient_wire;
    wire [7:0] remainder_wire;
    wire overflow_wire;

    // Instantiate the division controller
    divider_controller controller (
        .a(a),
        .b(b),
        .quotient(quotient_wire),
        .remainder(remainder_wire),
        .overflow(overflow_wire)
    );

    // Output assignments
    assign quotient = quotient_wire;
    assign remainder = remainder_wire;
    assign overflow = overflow_wire;

endmodule

// Division controller module
module divider_controller (
    input [7:0] a,
    input [7:0] b,
    output [7:0] quotient,
    output [7:0] remainder,
    output overflow
);

    wire [7:0] quotient_wire;
    wire [7:0] remainder_wire;
    wire overflow_wire;

    // Check for division by zero
    zero_checker zero_check (
        .b(b),
        .overflow(overflow_wire)
    );

    // Perform division if not dividing by zero
    division_core div_core (
        .a(a),
        .b(b),
        .valid(~overflow_wire),
        .quotient(quotient_wire),
        .remainder(remainder_wire)
    );

    // Output assignments
    assign quotient = overflow_wire ? 8'b00000000 : quotient_wire;
    assign remainder = overflow_wire ? 8'b00000000 : remainder_wire;
    assign overflow = overflow_wire;

endmodule

// Zero checker module
module zero_checker (
    input [7:0] b,
    output overflow
);

    assign overflow = (b == 8'b00000000);

endmodule

// Division core module
module division_core (
    input [7:0] a,
    input [7:0] b,
    input valid,
    output [7:0] quotient,
    output [7:0] remainder
);

    reg [7:0] quotient_reg;
    reg [7:0] remainder_reg;
    reg [8:0] dividend;
    reg [7:0] divisor;
    reg [3:0] counter;

    always @(*) begin
        if (!valid) begin
            quotient_reg = 8'b00000000;
            remainder_reg = 8'b00000000;
        end else begin
            dividend = {1'b0, a};
            divisor = b;
            quotient_reg = 8'b00000000;
            counter = 4'd8;
            
            while (counter > 0) begin
                dividend = {dividend[7:0], 1'b0};
                quotient_reg = {quotient_reg[6:0], 1'b0};
                
                if (dividend[8:1] >= divisor) begin
                    dividend[8:1] = dividend[8:1] - divisor;
                    quotient_reg[0] = 1'b1;
                end
                
                counter = counter - 1;
            end
            
            remainder_reg = dividend[7:0];
        end
    end

    assign quotient = quotient_reg;
    assign remainder = remainder_reg;

endmodule