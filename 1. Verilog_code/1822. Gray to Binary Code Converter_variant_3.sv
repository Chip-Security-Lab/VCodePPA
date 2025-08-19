//SystemVerilog
module gray2bin_unit #(parameter DATA_WIDTH = 8) (
    input  [DATA_WIDTH-1:0] gray_data,
    output [DATA_WIDTH-1:0] binary_data
);
    // 优化的Gray码转二进制码转换实现
    genvar i;
    generate
        // 最高位保持不变
        assign binary_data[DATA_WIDTH-1] = gray_data[DATA_WIDTH-1];
        
        // 其他位使用异或级联实现
        for (i = DATA_WIDTH-2; i >= 0; i = i - 1) begin : xor_cascade
            assign binary_data[i] = binary_data[i+1] ^ gray_data[i];
        end
    endgenerate
endmodule