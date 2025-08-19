//SystemVerilog
module neg_edge_siso #(
    parameter DEPTH = 4
) (
    input  wire clk_n,  // 负边沿时钟
    input  wire arst_n, // 低电平有效异步复位
    input  wire sin,    // 串行输入
    output wire sout    // 串行输出
);
    // 前移寄存器实现
    reg [DEPTH:0] sr_rebalanced;
    
    // 负边沿触发的移位寄存器重定时实现
    always @(negedge clk_n or negedge arst_n) begin
        if (!arst_n) begin
            // 异步复位，清零所有触发器
            sr_rebalanced <= {(DEPTH+1){1'b0}};
        end
        else begin
            // 移位操作：直接将输入注册到第一级，并进行后续移位
            sr_rebalanced <= {sr_rebalanced[DEPTH-1:0], sin};
        end
    end
    
    // 输出现在直接从寄存器取出，消除了输出路径上的组合逻辑延迟
    assign sout = sr_rebalanced[DEPTH];
    
endmodule