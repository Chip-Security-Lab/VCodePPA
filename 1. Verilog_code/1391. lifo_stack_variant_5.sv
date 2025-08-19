//SystemVerilog
/* IEEE 1364-2005 Verilog标准 */
module lifo_stack #(
    parameter DW = 8,     // 数据宽度
    parameter DEPTH = 8,  // 堆栈深度
    parameter PTR_W = $clog2(DEPTH)  // 指针位宽自动计算
) (
    input wire clk,              // 时钟信号
    input wire rst_n,            // 低电平有效复位信号
    input wire push,             // 入栈控制信号
    input wire pop,              // 出栈控制信号
    input wire [DW-1:0] din,     // 入栈数据
    output wire [DW-1:0] dout,   // 出栈数据
    output wire full,            // 栈满指示
    output wire empty            // 栈空指示
);
    // 内存存储元素
    reg [DW-1:0] mem [0:DEPTH-1];
    
    // 堆栈指针
    reg [PTR_W:0] ptr;  // 额外一位用于满/空检测
    
    // 优化的满空状态检测 - 使用精确的比较值
    assign full = (ptr == DEPTH);
    assign empty = (ptr == 0);
    
    // 优化的内部控制信号 - 通过与条件组合减少比较延迟
    wire do_push = push & ~full;
    wire do_pop = pop & ~empty;
    
    // 高效的数据输出逻辑 - 直接使用ptr-1作为索引
    // 避免额外的减法操作和条件检查
    wire [PTR_W-1:0] top_index = ptr - 1'b1;
    assign dout = empty ? {DW{1'b0}} : mem[top_index];
    
    // 优化的堆栈操作逻辑 - 使用优先级编码提高效率
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ptr <= 0;
        end
        else begin
            if (do_push & ~do_pop) begin
                // 仅入栈 - 写入当前ptr位置并增加ptr
                mem[ptr[PTR_W-1:0]] <= din;
                ptr <= ptr + 1'b1;
            end
            else if (~do_push & do_pop) begin
                // 仅出栈 - 减少ptr
                ptr <= ptr - 1'b1;
            end
            else if (do_push & do_pop) begin
                // 同时入栈出栈 - 数据更新但ptr不变
                mem[top_index] <= din;
            end
            // 默认情况无需显式处理（保持不变）
        end
    end
endmodule