//SystemVerilog
module dual_port_buffer (
    input wire clk,
    input wire [31:0] write_data,
    input wire write_en,
    input wire read_en,
    output reg [31:0] read_data
);
    // 将buffer寄存器分为两部分，以优化数据流
    reg [31:0] buffer;
    reg write_en_r, read_en_r;
    reg [31:0] write_data_r;
    
    // 第一级寄存器 - 捕获输入信号
    always @(posedge clk) begin
        write_data_r <= write_data;
        write_en_r <= write_en;
        read_en_r <= read_en;
    end
    
    // 第二级寄存器 - 处理数据存储
    always @(posedge clk) begin
        if (write_en_r)
            buffer <= write_data_r;
    end
    
    // 输出逻辑 - 重定时后的读取操作
    always @(posedge clk) begin
        if (read_en_r) begin
            if (write_en_r) 
                read_data <= write_data_r;
            else
                read_data <= buffer;
        end
    end
endmodule