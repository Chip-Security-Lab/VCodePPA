//SystemVerilog
module MultiDriveNOT(
    input [7:0] vector,
    output [7:0] inverse
);
    // 实例化位操作子模块
    BitNotOperator bit_not_inst (
        .data_in(vector),
        .data_out(inverse)
    );
endmodule

module BitNotOperator(
    input [7:0] data_in,
    output [7:0] data_out
);
    // 参数化的位宽，提高可复用性
    parameter WIDTH = 8;
    
    // 使用生成块实现位反转，允许更细粒度的控制
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : not_gate_gen
            // 单比特反转，提高了资源利用率和时序性能
            assign data_out[i] = ~data_in[i];
        end
    endgenerate
endmodule