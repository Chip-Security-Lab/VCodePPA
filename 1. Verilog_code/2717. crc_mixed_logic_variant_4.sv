//SystemVerilog
// 顶层模块
module crc_mixed_logic (
    input clk,
    input [15:0] data_in,
    output [7:0] crc
);
    // 内部连线
    wire [7:0] xor_result;
    
    // 实例化数据处理子模块
    data_processor data_proc_inst (
        .data_in(data_in),
        .xor_result(xor_result)
    );
    
    // 实例化CRC生成子模块
    crc_generator crc_gen_inst (
        .clk(clk),
        .xor_data(xor_result),
        .crc_out(crc)
    );
    
endmodule

// 数据处理子模块 - 执行数据异或操作
module data_processor (
    input [15:0] data_in,
    output [7:0] xor_result
);
    // 将输入数据的高8位与低8位异或
    assign xor_result = data_in[15:8] ^ data_in[7:0];
    
endmodule

// CRC生成子模块 - 计算最终CRC值
module crc_generator (
    input clk,
    input [7:0] xor_data,
    output reg [7:0] crc_out
);
    // 旋转一位并与固定值异或
    always @(posedge clk) begin
        crc_out <= {xor_data[6:0], xor_data[7]} ^ 8'h07;
    end
    
endmodule