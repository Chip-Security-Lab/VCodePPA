//SystemVerilog
module nor2_conditional (
    input wire A,
    input wire B,
    output wire Y
);
    nor2_generic #(
        .WIDTH(1)
    ) u_nor2_generic (
        .in({A, B}),
        .out(Y)
    );
endmodule

module nor2_generic #(
    parameter WIDTH = 1
)(
    input  wire [WIDTH-1:0] in,
    output wire out
);
    assign out = ~(|in);
endmodule