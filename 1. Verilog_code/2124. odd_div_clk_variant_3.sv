//SystemVerilog
module odd_div_clk #(
    parameter N = 5
)(
    input wire clk_in,
    input wire reset,
    output wire clk_div
);
    // 计算分频系数的一半（向下取整）
    localparam HALF_COUNT = (N-1)/2;
    // 使用参数定义计数器位宽，避免固定的位宽限制
    localparam CNT_WIDTH = $clog2(HALF_COUNT+1);
    
    reg [CNT_WIDTH-1:0] posedge_counter;
    reg [CNT_WIDTH-1:0] negedge_counter;
    reg clk_p, clk_n;
    
    // 提前计算比较信号，减少关键路径
    wire posedge_terminal = (posedge_counter == HALF_COUNT);
    wire negedge_terminal = (negedge_counter == HALF_COUNT);
    
    // Posedge counter - 优化逻辑结构
    always @(posedge clk_in or posedge reset) begin
        if (reset) begin
            posedge_counter <= {CNT_WIDTH{1'b0}};
            clk_p <= 1'b0;
        end else begin
            posedge_counter <= posedge_terminal ? {CNT_WIDTH{1'b0}} : posedge_counter + 1'b1;
            clk_p <= posedge_terminal ? ~clk_p : clk_p;
        end
    end
    
    // Negedge counter - 优化逻辑结构
    always @(negedge clk_in or posedge reset) begin
        if (reset) begin
            negedge_counter <= {CNT_WIDTH{1'b0}};
            clk_n <= 1'b0;
        end else begin
            negedge_counter <= negedge_terminal ? {CNT_WIDTH{1'b0}} : negedge_counter + 1'b1;
            clk_n <= negedge_terminal ? ~clk_n : clk_n;
        end
    end
    
    // 使用简单的异或操作生成最终输出
    assign clk_div = clk_p ^ clk_n;
endmodule