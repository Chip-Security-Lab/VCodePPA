//SystemVerilog
module byte_enabled_buffer (
    input wire clk,
    input wire [31:0] data_in,
    input wire [3:0] byte_en,
    input wire valid,        // 替换原write信号，表示数据有效
    output reg ready,        // 新增ready信号，表示模块准备好接收数据
    output reg [31:0] data_out
);
    // 缓冲高扇出信号
    reg [31:0] data_in_buf1, data_in_buf2;
    reg [3:0] byte_en_buf1, byte_en_buf2;
    reg [31:0] data_out_buf;
    
    // 字节掩码数据及其缓冲
    reg [31:0] byte_masked_data;
    reg [31:0] byte_masked_data_buf;
    
    // 握手状态控制
    reg processing;
    reg data_valid;
    
    // 握手逻辑
    always @(posedge clk) begin
        if (!processing && valid) begin
            // 接收有效数据时，拉低ready直到处理完成
            ready <= 1'b0;
            processing <= 1'b1;
            data_valid <= 1'b1;
        end else if (processing && data_valid) begin
            // 数据正在处理中
            data_valid <= 1'b0;
        end else if (processing && !data_valid) begin
            // 数据处理完成
            processing <= 1'b0;
            ready <= 1'b1;
        end else begin
            // 默认状态：准备好接收数据
            ready <= 1'b1;
        end
    end
    
    // 第一级缓冲 - 分散输入信号负载
    always @(posedge clk) begin
        if (valid && ready) begin
            data_in_buf1 <= data_in;
            data_in_buf2 <= data_in;
            byte_en_buf1 <= byte_en;
            byte_en_buf2 <= byte_en;
        end
        data_out_buf <= data_out;
    end
    
    // 字节掩码计算 - 使用缓冲信号减少扇出负载
    always @(posedge clk) begin
        if (valid && ready) begin
            // 使用缓冲信号计算字节更新值，降低关键路径扇出负载
            byte_masked_data[7:0]   <= byte_en_buf1[0] ? data_in_buf1[7:0]   : data_out_buf[7:0];
            byte_masked_data[15:8]  <= byte_en_buf1[1] ? data_in_buf1[15:8]  : data_out_buf[15:8];
            byte_masked_data[23:16] <= byte_en_buf2[2] ? data_in_buf2[23:16] : data_out_buf[23:16];
            byte_masked_data[31:24] <= byte_en_buf2[3] ? data_in_buf2[31:24] : data_out_buf[31:24];
        end
    end
    
    // 缓冲字节掩码数据
    always @(posedge clk) begin
        if (processing && data_valid) begin
            byte_masked_data_buf <= byte_masked_data;
        end
    end
    
    // 最终输出更新
    always @(posedge clk) begin
        if (processing && !data_valid) begin
            data_out <= byte_masked_data_buf;
        end
    end

    // 复位初始化
    initial begin
        ready = 1'b1;
        processing = 1'b0;
        data_valid = 1'b0;
    end
endmodule