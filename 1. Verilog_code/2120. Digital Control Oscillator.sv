module digital_ctrl_osc(
    input enable,
    input [7:0] ctrl_word,
    input reset,
    output reg clk_out
);
    reg [7:0] delay_counter;
    reg internal_clk;  // 内部时钟源
    
    // 生成内部时钟（实际设计中应由外部时钟驱动）
    reg [3:0] clk_divider;
    always @(posedge reset or posedge internal_clk) begin
        if (reset)
            clk_divider <= 4'd0;
        else
            clk_divider <= clk_divider + 4'd1;
    end
    assign internal_clk = clk_divider[3]; // 分频模拟时钟源
    
    // 计数器逻辑
    always @(posedge internal_clk or posedge reset) begin
        if (reset) begin
            delay_counter <= 8'd0;
            clk_out <= 1'b0;
        end else if (enable) begin
            if (delay_counter >= ctrl_word) begin
                delay_counter <= 8'd0;
                clk_out <= ~clk_out;
            end else begin
                delay_counter <= delay_counter + 8'd1;
            end
        end
    end
endmodule