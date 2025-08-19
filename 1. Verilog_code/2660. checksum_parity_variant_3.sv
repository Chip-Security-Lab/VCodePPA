//SystemVerilog
module checksum_parity (
    input [31:0] data,           // 32位输入数据
    output reg parity_valid,     // 奇偶校验有效标志
    output reg [7:0] checksum    // 8位校验和结果
);
    // 内部连线
    wire [7:0] unpacked_data [0:3];
    wire [7:0] sum_result;
    wire parity_result;
    
    // 实例化数据解包模块
    data_unpacker u_data_unpacker (
        .packed_data(data),
        .unpacked_data(unpacked_data)
    );
    
    // 实例化求和模块
    sum_calculator u_sum_calculator (
        .data_array(unpacked_data),
        .sum_out(sum_result)
    );
    
    // 实例化奇偶校验模块
    parity_checker u_parity_checker (
        .data_in(sum_result),
        .parity_out(parity_result)
    );
    
    // 输出赋值
    always @(*) begin
        checksum = sum_result;
        parity_valid = parity_result;
    end
endmodule

// 数据解包模块 - 将32位打包数据拆分为4个8位数据
module data_unpacker (
    input [31:0] packed_data,
    output [7:0] unpacked_data [0:3]
);
    assign unpacked_data[0] = packed_data[7:0];
    assign unpacked_data[1] = packed_data[15:8];
    assign unpacked_data[2] = packed_data[23:16];
    assign unpacked_data[3] = packed_data[31:24];
endmodule

// 求和模块 - 计算4个8位数据的和
module sum_calculator (
    input [7:0] data_array [0:3],
    output [7:0] sum_out
);
    // 参数化设计，支持不同数量的输入
    parameter DATA_COUNT = 4;
    
    // 使用生成块和中间变量进行优化求和
    // 这种方法有助于提高时序性能
    wire [7:0] partial_sum [0:DATA_COUNT-2];
    
    assign partial_sum[0] = data_array[0] + data_array[1];
    
    genvar i;
    generate
        for (i = 1; i < DATA_COUNT-1; i = i + 1) begin : sum_gen
            assign partial_sum[i] = partial_sum[i-1] + data_array[i+1];
        end
    endgenerate
    
    assign sum_out = partial_sum[DATA_COUNT-2];
endmodule

// 奇偶校验模块 - 计算输入数据的奇偶校验
module parity_checker (
    input [7:0] data_in,
    output parity_out
);
    assign parity_out = ^data_in;
endmodule