//SystemVerilog
module basic_clock_divider(
    input wire clk_in,
    input wire rst_n,
    output reg clk_out
);
    // 计数器寄存器
    reg [3:0] counter;
    // 计数器达到目标值的标志信号
    reg counter_max;
    
    // 计数器逻辑
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 4'd0;
        end else begin
            if (counter == 4'd9) begin
                counter <= 4'd0;
            end else begin
                counter <= counter + 1'b1;
            end
        end
    end
    
    // 计数器最大值检测逻辑
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            counter_max <= 1'b0;
        end else begin
            counter_max <= (counter == 4'd9);
        end
    end
    
    // 输出时钟切换逻辑
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            clk_out <= 1'b0;
        end else if (counter_max) begin
            clk_out <= ~clk_out;
        end
    end
endmodule