//SystemVerilog
`timescale 1ns / 1ps
module digital_ctrl_osc(
    input enable,
    input [7:0] ctrl_word,
    input reset,
    output reg clk_out
);
    reg [7:0] delay_counter;
    
    // 使用更高效的时钟生成逻辑
    reg [3:0] clk_divider;
    wire internal_clk;
    
    // 添加缓冲寄存器用于高扇出的clk_divider[3]信号
    reg clk_divider_buf1, clk_divider_buf2;
    
    // 时钟分频器
    always @(posedge reset or negedge clk_divider_buf1) begin
        if (reset)
            clk_divider <= 4'd0;
        else
            clk_divider <= clk_divider + 4'd1;
    end
    
    // 为高扇出的clk_divider[3]信号添加缓冲
    always @(*) begin
        clk_divider_buf1 = clk_divider[3];
        clk_divider_buf2 = clk_divider[3];
    end
    
    assign internal_clk = clk_divider_buf2; // 使用缓冲后的时钟信号
    
    // 优化后的计数器和比较逻辑
    always @(posedge internal_clk or posedge reset) begin
        if (reset) begin
            delay_counter <= 8'd0;
            clk_out <= 1'b0;
        end else if (enable) begin
            // 使用比较器的优化结构，避免大于等于比较
            if (delay_counter == ctrl_word) begin
                delay_counter <= 8'd0;
                clk_out <= ~clk_out;
            end else begin
                delay_counter <= delay_counter + 8'd1;
            end
        end
    end
endmodule