//SystemVerilog
// 顶层模块
module crc_mixed_logic (
    input clk,
    input [15:0] data_in,
    output reg [7:0] crc
);

    wire [7:0] xor_result;
    wire [7:0] rotated_result;
    wire [7:0] final_result;

    // 实例化异或计算子模块
    xor_calc u_xor_calc (
        .data_in(data_in),
        .xor_result(xor_result)
    );

    // 实例化循环移位子模块
    rotate_logic u_rotate_logic (
        .data_in(xor_result),
        .rotated_result(rotated_result)
    );

    // 实例化常量异或子模块
    const_xor u_const_xor (
        .data_in(rotated_result),
        .final_result(final_result)
    );

    // 寄存器输出
    always @(posedge clk) begin
        crc <= final_result;
    end

endmodule

// 异或计算子模块
module xor_calc (
    input [15:0] data_in,
    output [7:0] xor_result
);
    assign xor_result = data_in[15:8] ^ data_in[7:0];
endmodule

// 循环移位子模块
module rotate_logic (
    input [7:0] data_in,
    output [7:0] rotated_result
);
    assign rotated_result = {data_in[6:0], data_in[7]};
endmodule

// 常量异或子模块
module const_xor (
    input [7:0] data_in,
    output [7:0] final_result
);
    assign final_result[0] = data_in[0] ^ 1'b1;
    assign final_result[1] = data_in[1] ^ 1'b1;
    assign final_result[2] = data_in[2] ^ 1'b1;
    assign final_result[3] = data_in[3];
    assign final_result[4] = data_in[4];
    assign final_result[5] = data_in[5];
    assign final_result[6] = data_in[6];
    assign final_result[7] = data_in[7];
endmodule