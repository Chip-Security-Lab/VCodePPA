//SystemVerilog
module hamming_16bit_enc_en(
    input clock, enable, clear,
    input [15:0] data_in,
    output reg [20:0] ham_out
);

    // 输入寄存和使能信号合并
    reg [15:0] data_reg;
    reg ctrl_reg;
    wire processing_active = ctrl_reg & ~clear;
    
    // 合并输入和控制寄存
    always @(posedge clock) begin
        data_reg <= data_in;
        ctrl_reg <= enable & ~clear;
    end

    // 优化的奇偶校验计算
    // 使用wire进行组合逻辑计算，减少寄存器使用
    wire p0, p1, p3, p7, p15;
    assign p0 = ^(data_reg & 16'b1010_1010_1010_1010);
    assign p1 = ^(data_reg & 16'b1100_1100_1100_1100); 
    assign p3 = ^(data_reg & 16'b1111_0000_1111_0000);
    assign p7 = ^(data_reg & 16'b1111_1111_0000_0000);
    assign p15 = ^data_reg; // 简化了全1掩码的异或操作

    // 直接从data_reg提取数据位，避免额外寄存
    wire [4:0] high_bits = data_reg[15:11];
    wire [6:0] mid_bits = data_reg[10:4]; 
    wire [3:0] low_bits = {data_reg[3:1], data_reg[0]};

    // 优化的输出组装 - 使用单一always块
    always @(posedge clock) begin
        if (clear)
            ham_out <= 21'b0;
        else if (processing_active) begin
            // 使用连接操作符一次性构建输出
            ham_out <= {high_bits, 
                       p15, 
                       mid_bits, 
                       p7, 
                       low_bits[3:1], 
                       p3, 
                       low_bits[0], 
                       p1, 
                       p0};
        end
    end

endmodule