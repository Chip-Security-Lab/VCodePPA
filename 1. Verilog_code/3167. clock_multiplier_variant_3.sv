//SystemVerilog
module clock_multiplier(
    input ref_clk,
    input resetn,
    output reg out_clk
);
    // 计数器和中间时钟信号
    reg [1:0] count;
    // 高扇出信号的缓冲寄存器
    reg [1:0] count_buf1;
    reg [1:0] count_buf2;
    reg int_clk;
    
    // 计数器逻辑 - 独立的always块处理计数
    always @(posedge ref_clk or negedge resetn) begin
        if (!resetn) begin
            count <= 2'd0;
        end else begin
            count <= count + 1'b1;
        end
    end
    
    // 缓冲寄存器1 - 为中间时钟生成逻辑提供专用count副本
    always @(posedge ref_clk or negedge resetn) begin
        if (!resetn) begin
            count_buf1 <= 2'd0;
        end else begin
            count_buf1 <= count;
        end
    end
    
    // 缓冲寄存器2 - 为其他可能的消费者提供专用count副本
    always @(posedge ref_clk or negedge resetn) begin
        if (!resetn) begin
            count_buf2 <= 2'd0;
        end else begin
            count_buf2 <= count;
        end
    end
    
    // 中间时钟生成逻辑 - 使用缓冲后的count_buf1而非直接使用count
    always @(posedge ref_clk or negedge resetn) begin
        if (!resetn) begin
            int_clk <= 1'b0;
        end else if (count_buf1 == 2'd1 || count_buf1 == 2'd3) begin
            int_clk <= ~int_clk;
        end
    end
    
    // 输出时钟生成逻辑
    always @(posedge int_clk or negedge resetn) begin
        if (!resetn) begin
            out_clk <= 1'b0;
        end else begin
            out_clk <= ~out_clk;
        end
    end
endmodule