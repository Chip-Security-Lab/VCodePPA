//SystemVerilog
module not_gate_param #(
    parameter WIDTH = 8
)(
    input wire [WIDTH-1:0] A,
    output wire [WIDTH-1:0] Y
);

    // 实例化基本非门单元
    not_gate_cell #(
        .WIDTH(WIDTH)
    ) u_not_gate_cell (
        .A(A),
        .Y(Y)
    );

endmodule

// 基本非门单元模块
module not_gate_cell #(
    parameter WIDTH = 8
)(
    input wire [WIDTH-1:0] A,
    output wire [WIDTH-1:0] Y
);

    // 使用generate语句生成多个非门
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : not_gate_array
            assign Y[i] = ~A[i];
        end
    endgenerate

endmodule