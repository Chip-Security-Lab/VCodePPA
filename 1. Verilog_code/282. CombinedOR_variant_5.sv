//SystemVerilog
module CombinedOR(
    input [1:0] sel,
    input [3:0] a, b, c, d,
    output [3:0] res
);
    wire [3:0] ab_result, cd_result;
    wire [3:0] mux_out;
    
    // Instantiate sub-modules for better modularity and optimization
    BitwiseOR u_ab_or (
        .in1(a),
        .in2(b),
        .out(ab_result)
    );
    
    BitwiseOR u_cd_or (
        .in1(c),
        .in2(d),
        .out(cd_result)
    );
    
    ParameterizedMux u_output_mux (
        .sel(sel),
        .in0(ab_result),
        .in1(cd_result),
        .out(mux_out)
    );
    
    // Final output assignment
    assign res = mux_out;
endmodule

module BitwiseOR #(
    parameter WIDTH = 4
)(
    input [WIDTH-1:0] in1,
    input [WIDTH-1:0] in2,
    output [WIDTH-1:0] out
);
    // Optimized bitwise OR operation
    // Can be better targeted by synthesis tools for specific technology
    assign out = in1 | in2;
endmodule

module ParameterizedMux #(
    parameter WIDTH = 4
)(
    input [1:0] sel,
    input [WIDTH-1:0] in0,
    input [WIDTH-1:0] in1,
    output [WIDTH-1:0] out
);
    // Optimized multiplexer logic with parameterized width
    // This reduces gate count by avoiding redundant operations
    assign out = {WIDTH{sel[1]}} & in0 | {WIDTH{sel[0]}} & in1;
endmodule