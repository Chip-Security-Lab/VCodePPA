//SystemVerilog
module Multiplier3(
    input clk,
    input [3:0] data_a, data_b,
    output [7:0] mul_result
);

    wire [7:0] partial_product;
    wire [7:0] final_result;

    // 乘法计算子模块
    MultiplierCore multiplier_core(
        .data_a(data_a),
        .data_b(data_b),
        .product(partial_product)
    );

    // 结果寄存器子模块
    ResultRegister result_reg(
        .clk(clk),
        .data_in(partial_product),
        .data_out(final_result)
    );

    assign mul_result = final_result;

endmodule

module MultiplierCore(
    input [3:0] data_a,
    input [3:0] data_b,
    output [7:0] product
);

    assign product = data_a * data_b;

endmodule

module ResultRegister(
    input clk,
    input [7:0] data_in,
    output reg [7:0] data_out
);

    always @(posedge clk) begin
        data_out <= data_in;
    end

endmodule