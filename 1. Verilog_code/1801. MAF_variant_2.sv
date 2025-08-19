//SystemVerilog
module MAF #(parameter WIDTH=8, DEPTH=4) (
    input clk, rst_n, en,
    input [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);
    // 数据流缓冲区声明
    reg [WIDTH-1:0] buffer [0:DEPTH-1];
    // 前向数据路径寄存器
    reg [WIDTH-1:0] din_reg;
    // 分离累加器，减少关键路径
    reg [WIDTH+3:0] accumulator;
    // 优化：直接使用固定值除法，避免除法器实例化
    wire [WIDTH+3:0] avg_result = (accumulator + (DEPTH>>1)) >> $clog2(DEPTH);
    // 退出数据流路径信号
    reg [WIDTH-1:0] exit_data;
    
    // 重置控制信号
    wire reset = !rst_n;
    // 更新控制信号
    wire update = en & !reset;
    
    // 使用生成变量优化循环结构
    genvar g;
    
    // 输入和缓冲区管理 - 分离控制路径
    always @(posedge clk) begin
        if(reset) begin
            din_reg <= 0;
            exit_data <= 0;
        end else if(update) begin
            din_reg <= din;
            exit_data <= buffer[DEPTH-1];
        end
    end
    
    // 缓冲区更新 - 使用移位寄存器实现
    always @(posedge clk) begin
        if(reset) begin
            for(integer i=0; i<DEPTH; i=i+1)
                buffer[i] <= 0;
        end else if(update) begin
            for(integer i=DEPTH-1; i>0; i=i-1)
                buffer[i] <= buffer[i-1];
            buffer[0] <= din_reg;
        end
    end
    
    // 累加器和输出阶段
    always @(posedge clk) begin
        if(reset) begin
            accumulator <= 0;
            dout <= 0;
        end else if(update) begin
            // 优化: 一步更新累加，减少流水线级数
            accumulator <= accumulator + din_reg - exit_data;
            // 优化: 直接使用计算后的平均值，避免额外寄存器
            dout <= avg_result[WIDTH-1:0];
        end
    end
endmodule