//SystemVerilog
module crc8_serial (
    input wire clk,
    input wire rst_n,
    input wire valid,
    output reg ready,
    input wire [7:0] data_in,
    output reg [7:0] crc_out
);
    parameter POLY = 8'h07;
    
    // 内部信号定义
    reg crc_feedback;
    reg [7:0] crc_next;
    reg processing;
    
    // 计算CRC反馈比特
    always @(*) begin
        crc_feedback = crc_out[7];
    end
    
    // 计算CRC多项式XOR逻辑
    always @(*) begin
        if (crc_feedback)
            crc_next = {crc_out[6:0], 1'b0} ^ POLY ^ {data_in, 1'b0};
        else
            crc_next = {crc_out[6:0], 1'b0} ^ {data_in, 1'b0};
    end
    
    // Ready信号生成逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            ready <= 1'b1;
        else if (valid && ready)
            ready <= 1'b0;
        else if (!processing)
            ready <= 1'b1;
    end
    
    // 处理状态控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            processing <= 1'b0;
        else if (valid && ready)
            processing <= 1'b1;
        else if (processing)
            processing <= 1'b0;
    end
    
    // CRC计算和寄存器更新逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            crc_out <= 8'hFF;
        else if (valid && ready)
            crc_out <= crc_next;
    end
    
endmodule