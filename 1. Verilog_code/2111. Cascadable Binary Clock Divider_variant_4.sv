//SystemVerilog
module binary_clk_divider(
    input clk_i,
    input rst_i,
    output [3:0] clk_div  // 2^1, 2^2, 2^3, 2^4 division
);
    // 内部连线
    wire [3:0] counter_value;
    
    // 实例化计数器子模块
    counter_module counter_inst (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .count_o(counter_value)
    );
    
    // 实例化输出驱动子模块
    output_driver_module output_driver_inst (
        .count_i(counter_value),
        .clk_div_o(clk_div)
    );
    
endmodule

module counter_module(
    input clk_i,
    input rst_i,
    output reg [3:0] count_o
);
    // 参数化设计，便于将来扩展
    parameter COUNTER_WIDTH = 4;
    
    // 计数器逻辑
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            count_o <= {COUNTER_WIDTH{1'b0}};
        end else begin
            count_o <= count_o + 1'b1;
        end
    end
endmodule

module output_driver_module(
    input [3:0] count_i,
    output [3:0] clk_div_o
);
    // 将计数器输出直接连接到时钟分频输出
    assign clk_div_o = count_i;
endmodule