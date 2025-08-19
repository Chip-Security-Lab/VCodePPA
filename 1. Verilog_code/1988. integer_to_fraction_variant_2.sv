//SystemVerilog
// Top-level module: Hierarchically structured integer to fraction converter

module integer_to_fraction #(
    parameter INT_WIDTH = 8,
    parameter FRAC_WIDTH = 8
)(
    input  wire [INT_WIDTH-1:0] int_in,
    input  wire [INT_WIDTH-1:0] denominator,
    output wire [INT_WIDTH+FRAC_WIDTH-1:0] frac_out
);

    wire [INT_WIDTH+FRAC_WIDTH-1:0] extended_int;
    wire [INT_WIDTH+FRAC_WIDTH-1:0] division_out;

    // Integer Extension Submodule
    int_to_extender #(
        .INT_WIDTH(INT_WIDTH),
        .FRAC_WIDTH(FRAC_WIDTH)
    ) u_int_to_extender (
        .int_in(int_in),
        .extended_int(extended_int)
    );

    // Denominator Extender Submodule
    denom_extender #(
        .INT_WIDTH(INT_WIDTH),
        .FRAC_WIDTH(FRAC_WIDTH)
    ) u_denom_extender (
        .denominator_in(denominator),
        .denominator_ext(denominator_ext)
    );

    // Division Submodule
    int_frac_divider #(
        .DIV_WIDTH(INT_WIDTH+FRAC_WIDTH)
    ) u_int_frac_divider (
        .numerator(extended_int),
        .denominator(denominator_ext),
        .quotient(division_out)
    );

    assign frac_out = division_out;

    wire [INT_WIDTH+FRAC_WIDTH-1:0] denominator_ext;

endmodule

// -----------------------------------------------------------------------------
// 子模块：int_to_extender
// 功能：将输入整数左移FRAC_WIDTH位，实现小数扩展
// -----------------------------------------------------------------------------
module int_to_extender #(
    parameter INT_WIDTH = 8,
    parameter FRAC_WIDTH = 8
)(
    input  wire [INT_WIDTH-1:0] int_in,
    output wire [INT_WIDTH+FRAC_WIDTH-1:0] extended_int
);
    assign extended_int = {{(FRAC_WIDTH){1'b0}}, int_in} << FRAC_WIDTH;
endmodule

// -----------------------------------------------------------------------------
// 子模块：denom_extender
// 功能：将分母扩展为与分子等宽
// -----------------------------------------------------------------------------
module denom_extender #(
    parameter INT_WIDTH = 8,
    parameter FRAC_WIDTH = 8
)(
    input  wire [INT_WIDTH-1:0] denominator_in,
    output wire [INT_WIDTH+FRAC_WIDTH-1:0] denominator_ext
);
    assign denominator_ext = {{FRAC_WIDTH{1'b0}}, denominator_in};
endmodule

// -----------------------------------------------------------------------------
// 子模块：int_frac_divider
// 功能：对扩展后的整数进行除法，得到定点小数输出
// -----------------------------------------------------------------------------
module int_frac_divider #(
    parameter DIV_WIDTH = 16
)(
    input  wire [DIV_WIDTH-1:0] numerator,
    input  wire [DIV_WIDTH-1:0] denominator,
    output reg  [DIV_WIDTH-1:0] quotient
);
    always @* begin
        if (denominator != 0)
            quotient = numerator / denominator;
        else
            quotient = {DIV_WIDTH{1'b0}};
    end
endmodule