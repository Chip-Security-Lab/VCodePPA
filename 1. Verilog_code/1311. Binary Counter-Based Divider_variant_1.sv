//SystemVerilog
module binary_freq_div #(parameter WIDTH = 4) (
    input wire clk_in,
    input wire rst_n,
    output reg clk_out
);
    reg [WIDTH-2:0] count;
    wire count_max;
    
    // 检测计数器是否达到最大值
    assign count_max = (count == {(WIDTH-1){1'b1}});
    
    // 计数器逻辑 - 负责计数器自增操作
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            count <= {(WIDTH-1){1'b0}};
        end
        else begin
            count <= count + 1'b1;
        end
    end
    
    // 时钟输出逻辑 - 负责生成输出时钟信号
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            clk_out <= 1'b0;
        end
        else if (count_max) begin
            clk_out <= ~clk_out;
        end
    end
endmodule