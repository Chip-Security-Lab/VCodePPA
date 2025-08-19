//SystemVerilog
module prog_clock_gen(
    input i_clk,
    input i_rst_n,
    input i_enable,
    input [15:0] i_divisor,
    output reg o_clk
);
    reg [15:0] count;
    wire count_max;
    
    // 使用相等比较而非大于等于比较，节省比较器资源
    assign count_max = (count == (i_divisor - 16'd1));
    
    // 计数器逻辑 - 负责计数过程和计数器复位
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            count <= 16'd0;
        end else if (i_enable) begin
            if (count_max) begin
                count <= 16'd0;
            end else begin
                count <= count + 16'd1;
            end
        end
    end
    
    // 时钟输出逻辑 - 负责生成分频后的时钟信号
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            o_clk <= 1'b0;
        end else if (i_enable && count_max) begin
            o_clk <= ~o_clk;
        end
    end
endmodule