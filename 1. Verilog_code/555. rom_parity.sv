module rom_parity #(parameter BITS=12)(
    input [7:0] addr,
    output [BITS-1:0] data
);
    // 声明内存
    reg [BITS-2:0] mem [0:255];
    
    // 示例初始化
    initial begin
        // 将一些示例值设置为具体值用于综合
        mem[0] = 11'b10101010101;
        mem[1] = 11'b01010101010;
        // $readmemb("parity_data.bin", mem); // 仿真中使用
    end
    
    // 计算奇偶校验位并与数据组合
    wire [BITS-2:0] data_without_parity = mem[addr];
    wire parity_bit = ^data_without_parity;
    
    assign data = {parity_bit, data_without_parity};
endmodule