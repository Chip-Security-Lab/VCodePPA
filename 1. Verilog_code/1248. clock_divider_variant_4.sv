//SystemVerilog
//IEEE 1364-2005 Verilog标准
module clock_divider #(parameter DIVIDE_BY = 2) (
    input wire clk_in, reset,
    output reg clk_out
);
    // 最小所需位宽的计数器
    localparam COUNT_WIDTH = $clog2(DIVIDE_BY);
    localparam HALF_DIVIDE = DIVIDE_BY/2 - 1;
    
    // 优化流水线寄存器
    reg [COUNT_WIDTH-1:0] count_r;
    reg toggle_flag_r;
    reg clk_state_r;
    reg valid_r;
    
    // 预计算比较值，减少比较器延迟
    wire count_at_half = (count_r == HALF_DIVIDE);
    
    // 优化第一级流水线 - 计数逻辑与比较逻辑分离
    always @(posedge clk_in) begin
        if (reset) begin
            count_r <= 0;
            toggle_flag_r <= 0;
            valid_r <= 0;
        end else begin
            valid_r <= 1'b1;
            
            // 将计数逻辑与比较逻辑分离，减少关键路径
            count_r <= count_at_half ? {COUNT_WIDTH{1'b0}} : count_r + 1'b1;
            toggle_flag_r <= count_at_half;
        end
    end
    
    // 优化第二级流水线 - 时钟翻转逻辑简化
    always @(posedge clk_in) begin
        if (reset) begin
            clk_state_r <= 0;
            clk_out <= 0;
        end else if (valid_r) begin
            // 简化条件判断，减少关键路径
            clk_state_r <= toggle_flag_r ? ~clk_state_r : clk_state_r;
            clk_out <= clk_state_r;
        end
    end
endmodule