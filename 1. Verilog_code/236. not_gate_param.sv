module not_gate_param #(
    parameter WIDTH = 8
)(
    input wire [WIDTH-1:0] A,
    output wire [WIDTH-1:0] Y
);
    assign Y = ~A;
endmodule