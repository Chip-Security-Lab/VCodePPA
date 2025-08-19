//SystemVerilog
module autoincrement_buffer (
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    input wire write,
    input wire read,
    output reg [7:0] data_out
);
    reg [7:0] memory [0:15];
    reg [3:0] write_addr;
    reg [3:0] read_addr;
    
    // 前向重定时：将输入数据和控制信号的寄存移除，直接处理
    // 将存储器写入逻辑前移
    always @(posedge clk) begin
        if (rst) begin
            write_addr <= 4'b0;
        end else if (write) begin
            memory[write_addr] <= data_in; // 直接使用输入数据
            write_addr <= write_addr + 1;
        end
    end
    
    // 读取地址管理
    always @(posedge clk) begin
        if (rst) begin
            read_addr <= 4'b0;
        end else if (read) begin
            read_addr <= read_addr + 1;
        end
    end
    
    // 流水线阶段1 - 读取控制
    reg read_valid_stage1;
    
    always @(posedge clk) begin
        if (rst) begin
            read_valid_stage1 <= 1'b0;
        end else begin
            read_valid_stage1 <= read;
        end
    end
    
    // 流水线阶段2 - 读取数据和有效性
    reg [7:0] read_data_stage2;
    reg read_valid_stage2;
    
    always @(posedge clk) begin
        if (rst) begin
            read_data_stage2 <= 8'b0;
            read_valid_stage2 <= 1'b0;
        end else begin
            read_valid_stage2 <= read_valid_stage1;
            if (read_valid_stage1) begin
                read_data_stage2 <= memory[read_addr-1]; // 使用前一周期的地址
            end
        end
    end
    
    // 输出阶段
    always @(posedge clk) begin
        if (rst) begin
            data_out <= 8'b0;
        end else if (read_valid_stage2) begin
            data_out <= read_data_stage2;
        end
    end
    
endmodule