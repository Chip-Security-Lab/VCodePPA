//SystemVerilog
module prog_clk_gen(
    input  wire       pclk,      // 输入时钟
    input  wire       presetn,   // 异步复位信号，低有效
    input  wire [7:0] div_ratio, // 分频比设置
    output reg        clk_out    // 输出时钟
);
    // 内部信号声明
    reg  [7:0] counter_r;        // 计数器寄存器
    reg  [7:0] half_div_r;       // 分频半值寄存器
    wire [7:0] half_div_w;       // 分频半值线网
    wire       terminal_count;   // 终止计数标志
    
    // ==== 第一级流水线：输入处理阶段 ====
    // 计算分频比的一半
    assign half_div_w = {1'b0, div_ratio[7:1]};
    
    // 寄存半分频值以切分数据路径，降低组合逻辑深度
    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            half_div_r <= 8'd0;
        end else begin
            half_div_r <= half_div_w;
        end
    end
    
    // ==== 第二级流水线：计数器阶段 ====
    // 终止计数条件检测 - 分割复杂路径
    assign terminal_count = (counter_r >= half_div_r - 1'b1);
    
    // 计数器逻辑 - 负责计数和复位操作
    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            counter_r <= 8'd0;
        end else begin
            if (terminal_count) begin
                counter_r <= 8'd0;
            end else begin
                counter_r <= counter_r + 1'b1;
            end
        end
    end
    
    // ==== 第三级流水线：输出生成阶段 ====
    // 时钟输出逻辑 - 根据计数器生成输出时钟
    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            clk_out <= 1'b0;
        end else if (terminal_count) begin
            clk_out <= ~clk_out;
        end
    end
    
endmodule