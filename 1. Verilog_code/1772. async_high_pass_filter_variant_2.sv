//SystemVerilog
module async_high_pass_filter #(
    parameter DATA_WIDTH = 10
)(
    input wire clk,
    input wire rst_n,
    input wire [DATA_WIDTH-1:0] signal_input,
    input wire [DATA_WIDTH-1:0] avg_input,
    output wire [DATA_WIDTH-1:0] filtered_out
);
    // 内部寄存器声明
    reg [DATA_WIDTH-1:0] signal_input_reg;
    reg [DATA_WIDTH-1:0] avg_input_reg;
    reg [DATA_WIDTH-1:0] filter_result_reg;
    
    // 输入缓冲和滤波计算合并为一个时钟周期
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            signal_input_reg <= {DATA_WIDTH{1'b0}};
            avg_input_reg <= {DATA_WIDTH{1'b0}};
            filter_result_reg <= {DATA_WIDTH{1'b0}};
        end else begin
            signal_input_reg <= signal_input;
            avg_input_reg <= avg_input;
            filter_result_reg <= signal_input - avg_input;
        end
    end
    
    // 输出赋值
    assign filtered_out = filter_result_reg;
    
endmodule