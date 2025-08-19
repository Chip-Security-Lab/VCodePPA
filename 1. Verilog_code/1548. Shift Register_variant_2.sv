//SystemVerilog
module borrow_subtractor (
    input wire clk,
    input wire rst_n,
    input wire [7:0] minuend, // 被减数
    input wire [7:0] subtrahend, // 减数
    output reg [7:0] difference, // 差
    output reg borrow_out // 借位输出
);
    reg [7:0] lookup_table [0:255]; // 查找表
    reg [7:0] borrow; // 借位寄存器
    integer i;

    // 初始化查找表
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            lookup_table[i] = i; // 填充查找表
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            difference <= 0;
            borrow <= 0;
            borrow_out <= 0;
        end else begin
            borrow[0] = (minuend[0] < subtrahend[0]) ? 1 : 0; // 第0位借位
            difference[0] = lookup_table[minuend[0] - subtrahend[0]] - borrow[0]; // 使用查找表计算差
            for (i = 1; i < 8; i = i + 1) begin
                borrow[i] = (minuend[i] < (subtrahend[i] + borrow[i-1])) ? 1 : 0; // 计算借位
                difference[i] = lookup_table[minuend[i] - subtrahend[i]] - borrow[i-1]; // 使用查找表计算差
            end
            borrow_out = borrow[7]; // 最后一个借位作为借位输出
        end
    end
endmodule