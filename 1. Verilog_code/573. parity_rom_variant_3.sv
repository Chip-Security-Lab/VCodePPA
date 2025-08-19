//SystemVerilog
module parity_rom (
    input [3:0] addr,
    output [7:0] data,
    output parity_error
);
    wire [8:0] rom_data;
    
    // ROM 存储子模块
    memory_block mem_inst (
        .addr(addr),
        .data_out(rom_data)
    );
    
    // 奇偶校验检测子模块
    parity_checker parity_inst (
        .data_in(rom_data[7:0]),
        .stored_parity(rom_data[8]),
        .parity_mismatch(parity_error)
    );
    
    // 数据输出赋值
    assign data = rom_data[7:0];
    
endmodule

module memory_block (
    input [3:0] addr,
    output reg [8:0] data_out
);
    // 参数化的ROM大小
    parameter ROM_DEPTH = 16;
    
    // ROM存储（使用reg数组）
    reg [8:0] rom_memory [0:ROM_DEPTH-1];
    
    // ROM初始化 - 使用预计算的奇偶校验位
    initial begin
        // 数据格式: [奇偶校验位, 8位数据]
        rom_memory[0] = 9'b000100010; // Data = 0x12, Parity = 0
        rom_memory[1] = 9'b001101000; // Data = 0x34, Parity = 0
        rom_memory[2] = 9'b010101101; // Data = 0x56, Parity = 1
        rom_memory[3] = 9'b011110000; // Data = 0x78, Parity = 0
        // 未使用的地址空间初始化为0，采用批量赋值
        rom_memory[4] = 9'h000;
        rom_memory[5] = 9'h000;
        rom_memory[6] = 9'h000;
        rom_memory[7] = 9'h000;
        rom_memory[8] = 9'h000;
        rom_memory[9] = 9'h000;
        rom_memory[10] = 9'h000;
        rom_memory[11] = 9'h000;
        rom_memory[12] = 9'h000;
        rom_memory[13] = 9'h000;
        rom_memory[14] = 9'h000;
        rom_memory[15] = 9'h000;
    end
    
    // 优化的读取逻辑，增加地址有效性检查
    always @(*) begin
        if (addr < ROM_DEPTH) begin
            data_out = rom_memory[addr];
        end else begin
            data_out = 9'h000; // 无效地址返回0
        end
    end
endmodule

module parity_checker (
    input [7:0] data_in,
    input stored_parity,
    output reg parity_mismatch
);
    // 优化的奇偶校验计算，使用查找表加速
    wire [3:0] parity_lut [0:15];
    reg [3:0] nibble_parity;
    
    // 初始化4位查找表以提高并行性
    assign parity_lut[0] = 4'b0000;  // 0位为1
    assign parity_lut[1] = 4'b0001;  // 1位为1
    assign parity_lut[2] = 4'b0001;  // 1位为1
    assign parity_lut[3] = 4'b0010;  // 2位为1
    assign parity_lut[4] = 4'b0001;  // 1位为1
    assign parity_lut[5] = 4'b0010;  // 2位为1
    assign parity_lut[6] = 4'b0010;  // 2位为1
    assign parity_lut[7] = 4'b0011;  // 3位为1
    assign parity_lut[8] = 4'b0001;  // 1位为1
    assign parity_lut[9] = 4'b0010;  // 2位为1
    assign parity_lut[10] = 4'b0010; // 2位为1
    assign parity_lut[11] = 4'b0011; // 3位为1
    assign parity_lut[12] = 4'b0010; // 2位为1
    assign parity_lut[13] = 4'b0011; // 3位为1
    assign parity_lut[14] = 4'b0011; // 3位为1
    assign parity_lut[15] = 4'b0100; // 4位为1
    
    // 使用查找表计算奇偶校验
    always @(*) begin
        nibble_parity[0] = parity_lut[data_in[3:0]][0];
        nibble_parity[1] = parity_lut[data_in[7:4]][0];
        nibble_parity[2] = 1'b0;
        nibble_parity[3] = 1'b0;
        
        // 计算并比较奇偶校验
        parity_mismatch = (stored_parity != (nibble_parity[0] ^ nibble_parity[1]));
    end
endmodule