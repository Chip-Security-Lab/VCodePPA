//SystemVerilog
module ring_counter_async (
    input clk, rst_n, en,
    output reg [3:0] ring_pattern
);
    // 添加缓冲寄存器用于复位信号和使能信号
    reg rst_n_buf1, rst_n_buf2;
    reg en_buf1, en_buf2;
    
    // 内部环形计数器状态
    reg [3:0] next_pattern;
    
    // 缓冲复位信号，减少扇出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rst_n_buf1 <= 1'b0;
            rst_n_buf2 <= 1'b0;
        end else begin
            rst_n_buf1 <= 1'b1;
            rst_n_buf2 <= rst_n_buf1;
        end
    end
    
    // 缓冲使能信号，减少扇出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            en_buf1 <= 1'b0;
            en_buf2 <= 1'b0;
        end else begin
            en_buf1 <= en;
            en_buf2 <= en_buf1;
        end
    end
    
    // 计算下一状态逻辑
    always @(*) begin
        if (en_buf2)
            next_pattern = {ring_pattern[2:0], ring_pattern[3]}; // 左移操作
        else
            next_pattern = 4'b0000; // 使能为低时，输出全零
    end

    // 寄存器更新逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            ring_pattern <= 4'b0001; // 异步复位为初始状态
        else if (rst_n_buf2)
            ring_pattern <= next_pattern; // 使用缓冲的复位信号
    end

endmodule