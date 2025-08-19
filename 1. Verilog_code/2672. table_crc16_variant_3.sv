//SystemVerilog
module table_crc16(
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    input wire data_en,
    output wire [15:0] crc_result
);
    // 内部连线
    wire [15:0] crc_temp;
    wire [7:0] table_idx;
    wire [15:0] table_lookup;
    wire [15:0] shifted_crc;
    
    // 实例化子模块
    crc_input_processor input_proc (
        .crc_current(crc_result),
        .data_in(data_in),
        .crc_temp(crc_temp),
        .table_idx(table_idx)
    );
    
    crc_table_lookup lookup_unit (
        .index(table_idx),
        .table_value(table_lookup)
    );
    
    crc_barrel_shifter shift_unit (
        .crc_current(crc_result),
        .shifted_value(shifted_crc)
    );
    
    crc_register reg_unit (
        .clk(clk),
        .reset(reset),
        .data_en(data_en),
        .next_crc(shifted_crc ^ table_lookup),
        .crc_out(crc_result)
    );
endmodule

// 输入处理模块 - 准备CRC计算的中间值
module crc_input_processor(
    input wire [15:0] crc_current,
    input wire [7:0] data_in,
    output wire [15:0] crc_temp,
    output wire [7:0] table_idx
);
    // 计算XOR结果和查表索引
    assign crc_temp = crc_current ^ {8'h00, data_in};
    assign table_idx = crc_temp[7:0];
endmodule

// CRC表查找模块 - 从查找表中检索CRC值
module crc_table_lookup(
    input wire [7:0] index,
    output reg [15:0] table_value
);
    // ROM表实现 - 使用always_comb替代always @(*)以提高综合效率
    reg [15:0] crc_table [0:255];
    
    // 组合逻辑，不需要时钟
    always @(*) begin
        table_value = crc_table[index];
    end
    
    // 初始化查找表 (通常会在实际实现中提供，这里为示例)
    initial begin
        // 这里仅为示例填充，实际值需要根据具体的CRC多项式计算
        integer i;
        for (i = 0; i < 256; i = i + 1) begin
            crc_table[i] = 16'h0000; // 实际实现中会有正确的值
        end
    end
endmodule

// CRC桶形移位器模块 - 使用多路复用器结构实现8位右移
module crc_barrel_shifter(
    input wire [15:0] crc_current,
    output wire [15:0] shifted_value
);
    // 使用桶形移位器结构实现8位右移
    // 固定移位8位，因此无需多级桶形结构，直接映射信号
    assign shifted_value[7:0] = 8'h00;  // 高8位移出，低8位补0
    assign shifted_value[15:8] = crc_current[15:8];  // 原高8位移动到低8位
endmodule

// CRC寄存器模块 - 管理CRC计算状态
module crc_register(
    input wire clk,
    input wire reset,
    input wire data_en,
    input wire [15:0] next_crc,
    output reg [15:0] crc_out
);
    // 更新CRC寄存器
    always @(posedge clk) begin
        if (reset)
            crc_out <= 16'hFFFF;
        else if (data_en)
            crc_out <= next_crc;
    end
endmodule