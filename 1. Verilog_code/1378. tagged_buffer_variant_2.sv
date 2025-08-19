//SystemVerilog IEEE 1364-2005
module tagged_buffer (
    input wire clk,
    input wire reset_n,
    input wire [15:0] data_in,
    input wire [3:0] tag_in,
    input wire valid_in,
    output wire ready_out,
    output reg [15:0] data_out,
    output reg [3:0] tag_out,
    output reg valid_out,
    input wire ready_in
);

    // 内部控制信号
    reg buffer_full;
    reg [15:0] data_buffer;
    reg [3:0] tag_buffer;
    
    // 为高扇出信号添加缓冲寄存器
    reg [15:0] data_in_buf1, data_in_buf2;
    reg [3:0] tag_in_buf1, tag_in_buf2;
    reg valid_in_buf;
    reg ready_in_buf;
    
    // 内部控制信号缓冲
    reg b0_buf1, b0_buf2;
    reg b1_buf1, b1_buf2;
    
    // 控制信号生成与缓冲
    wire b0 = valid_out && ready_in;
    wire b1 = valid_in && ready_out;
    
    // Ready信号生成
    assign ready_out = !buffer_full || ready_in;
    
    // 数据输入缓冲 - 分级以分散负载
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            data_in_buf1 <= 16'b0;
            data_in_buf2 <= 16'b0;
        end else begin
            data_in_buf1 <= data_in;
            data_in_buf2 <= data_in;
        end
    end
    
    // 标签输入缓冲
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            tag_in_buf1 <= 4'b0;
            tag_in_buf2 <= 4'b0;
        end else begin
            tag_in_buf1 <= tag_in;
            tag_in_buf2 <= tag_in;
        end
    end
    
    // 控制信号缓冲
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            valid_in_buf <= 1'b0;
            ready_in_buf <= 1'b0;
        end else begin
            valid_in_buf <= valid_in;
            ready_in_buf <= ready_in;
        end
    end
    
    // 内部控制信号缓冲
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            b0_buf1 <= 1'b0;
            b0_buf2 <= 1'b0;
            b1_buf1 <= 1'b0;
            b1_buf2 <= 1'b0;
        end else begin
            b0_buf1 <= b0;
            b0_buf2 <= b0;
            b1_buf1 <= b1;
            b1_buf2 <= b1;
        end
    end
    
    // 数据输出逻辑 - 处理b0条件（输出被接收）
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            valid_out <= 1'b0;
        end else if (b0_buf1) begin
            if (buffer_full) begin
                valid_out <= 1'b1;
            end else if (valid_in_buf) begin
                valid_out <= 1'b1;
            end else begin
                valid_out <= 1'b0;
            end
        end else if (b1_buf1 && !valid_out) begin
            valid_out <= 1'b1;
        end
    end
    
    // 数据和标签输出处理
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            data_out <= 16'b0;
            tag_out <= 4'b0;
        end else if (b0_buf1) begin
            if (buffer_full) begin
                data_out <= data_buffer;
                tag_out <= tag_buffer;
            end else if (valid_in_buf) begin
                data_out <= data_in_buf1;
                tag_out <= tag_in_buf1;
            end
        end else if (b1_buf1 && (!valid_out || ready_in_buf)) begin
            data_out <= data_in_buf2;
            tag_out <= tag_in_buf2;
        end
    end
    
    // 缓冲区状态和数据管理
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            buffer_full <= 1'b0;
            data_buffer <= 16'b0;
            tag_buffer <= 4'b0;
        end else if (b0_buf1 && buffer_full) begin
            // 如果输出数据被接收且缓冲区有数据，清空缓冲区
            buffer_full <= 1'b0;
        end else if (b1_buf1 && valid_out && !ready_in_buf) begin
            // 如果有新数据但输出被阻塞，存入缓冲区
            buffer_full <= 1'b1;
            data_buffer <= data_in_buf2;
            tag_buffer <= tag_in_buf2;
        end
    end
    
endmodule