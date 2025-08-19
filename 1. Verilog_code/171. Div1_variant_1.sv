//SystemVerilog
module Div1(
    input [7:0] dividend,
    input [7:0] divisor,
    output [7:0] quotient
);

    wire [7:0] valid_divisor;
    wire division_valid;
    wire [7:0] division_result;

    DivisorValidator div_validator(
        .divisor(divisor),
        .valid_divisor(valid_divisor),
        .division_valid(division_valid)
    );

    NonRestoringDivider div_core(
        .dividend(dividend),
        .divisor(valid_divisor),
        .quotient(division_result)
    );

    ResultSelector result_selector(
        .division_result(division_result),
        .division_valid(division_valid),
        .quotient(quotient)
    );

endmodule

module DivisorValidator(
    input [7:0] divisor,
    output [7:0] valid_divisor,
    output division_valid
);

    assign division_valid = (divisor != 8'h0);
    assign valid_divisor = (divisor == 8'h0) ? 8'h1 : divisor;

endmodule

module NonRestoringDivider(
    input [7:0] dividend,
    input [7:0] divisor,
    output [7:0] quotient
);

    reg [7:0] q;
    reg [8:0] r;
    reg [7:0] d;
    integer i;

    always @(*) begin
        q = 0;
        r = {1'b0, dividend};
        d = divisor;
        
        for(i = 0; i < 8; i = i + 1) begin
            if(r[8] == 0) begin
                r = {r[7:0], 1'b0} - {1'b0, d};
                q = {q[6:0], 1'b1};
            end else begin
                r = {r[7:0], 1'b0} + {1'b0, d};
                q = {q[6:0], 1'b0};
            end
        end
        
        if(r[8] == 1) begin
            r = r + {1'b0, d};
        end
    end

    assign quotient = q;

endmodule

module ResultSelector(
    input [7:0] division_result,
    input division_valid,
    output [7:0] quotient
);

    assign quotient = division_valid ? division_result : 8'hFF;

endmodule