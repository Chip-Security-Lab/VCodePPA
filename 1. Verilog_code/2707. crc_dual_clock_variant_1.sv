//SystemVerilog
module crc_dual_clock (
    input clk_a, clk_b, rst,
    input [7:0] data_a,
    output reg [15:0] crc_b
);
    // 中间寄存器
    reg [7:0] data_sync_1, data_sync_2;
    reg [15:0] crc_reg;
    reg [15:0] crc_next;
    
    // 时钟域A: 数据捕获
    always @(posedge clk_a) begin
        data_sync_1 <= data_a;
    end
    
    // 时钟域B: 跨时钟域同步
    always @(posedge clk_b) begin
        data_sync_2 <= data_sync_1;
    end
    
    // 时钟域B: CRC计算逻辑
    always @(*) begin
        if (crc_reg[15])
            crc_next = {crc_reg[14:0], 1'b0} ^ 16'h8005 ^ {8'h00, data_sync_2};
        else
            crc_next = {crc_reg[14:0], 1'b0} ^ {8'h00, data_sync_2};
    end
    
    // 时钟域B: CRC寄存器更新
    always @(posedge clk_b) begin
        if (rst)
            crc_reg <= 16'hFFFF;
        else
            crc_reg <= crc_next;
    end
    
    // 时钟域B: 输出寄存器更新
    always @(posedge clk_b) begin
        crc_b <= crc_reg;
    end
endmodule