//SystemVerilog
module divider_param #(
    parameter WIDTH = 32
)(
    input  [WIDTH-1:0] dividend,
    input  [WIDTH-1:0] divisor,
    output [WIDTH-1:0] quotient,
    output [WIDTH-1:0] remainder
);

    wire [WIDTH-1:0] div_result;
    wire [WIDTH-1:0] rem_result;
    wire [WIDTH-1:0] quotient_reg;
    wire [WIDTH-1:0] remainder_reg;
    
    division_unit #(
        .WIDTH(WIDTH)
    ) div_unit (
        .dividend(dividend),
        .divisor(divisor),
        .quotient(div_result)
    );
    
    remainder_unit #(
        .WIDTH(WIDTH)
    ) rem_unit (
        .dividend(dividend),
        .divisor(divisor),
        .remainder(rem_result)
    );
    
    output_register #(
        .WIDTH(WIDTH)
    ) out_reg (
        .div_result(div_result),
        .rem_result(rem_result),
        .quotient(quotient_reg),
        .remainder(remainder_reg)
    );

    assign quotient = quotient_reg;
    assign remainder = remainder_reg;
    
endmodule

module division_unit #(
    parameter WIDTH = 32
)(
    input  [WIDTH-1:0] dividend,
    input  [WIDTH-1:0] divisor,
    output [WIDTH-1:0] quotient
);

    wire [WIDTH-1:0] div_result;
    wire [WIDTH-1:0] all_ones = {WIDTH{1'b1}};
    
    assign div_result = dividend / divisor;
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : mux_gen
            assign quotient[i] = (divisor != 0) ? div_result[i] : all_ones[i];
        end
    endgenerate
    
endmodule

module remainder_unit #(
    parameter WIDTH = 32
)(
    input  [WIDTH-1:0] dividend,
    input  [WIDTH-1:0] divisor,
    output [WIDTH-1:0] remainder
);

    wire [WIDTH-1:0] rem_result;
    
    assign rem_result = dividend % divisor;
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : mux_gen
            assign remainder[i] = (divisor != 0) ? rem_result[i] : dividend[i];
        end
    endgenerate
    
endmodule

module output_register #(
    parameter WIDTH = 32
)(
    input  [WIDTH-1:0] div_result,
    input  [WIDTH-1:0] rem_result,
    output reg [WIDTH-1:0] quotient,
    output reg [WIDTH-1:0] remainder
);

    always @(*) begin
        quotient = div_result;
        remainder = rem_result;
    end
    
endmodule