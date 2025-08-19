//SystemVerilog
module rle_buffer #(parameter DW=8) (
    input clk, en,
    input [DW-1:0] din,
    output reg [2*DW-1:0] dout
);
    // 数据缓存和计数器
    reg [DW-1:0] prev;
    reg [DW-1:0] count = 0;
    
    // 控制信号
    reg update_output;
    reg reset_counter;
    
    // 用于条件反相减法器的信号
    wire [DW-1:0] din_inv;
    
    // 流水线寄存器 - 第一级
    reg [DW-1:0] din_reg;
    reg [DW-1:0] prev_reg;
    reg en_reg;
    
    // 流水线寄存器 - 第二级
    reg [DW-1:0] difference;
    reg diff_flag;
    reg en_pipe2;
    
    // 将长组合逻辑分解为多个流水线级
    assign din_inv = ~din;
    
    // 第一级流水线 - 寄存输入信号
    always @(posedge clk) begin
        din_reg <= din;
        prev_reg <= prev;
        en_reg <= en;
    end
    
    // 第二级流水线 - 执行减法运算
    always @(posedge clk) begin
        {diff_flag, difference} <= prev_reg + (~din_reg) + 1'b1;
        en_pipe2 <= en_reg;
    end
    
    // 第三级 - 检测数据变化并生成控制信号
    always @(posedge clk) begin
        if (en_pipe2) begin
            update_output <= |difference;
            reset_counter <= |difference;
        end else begin
            update_output <= 1'b0;
            reset_counter <= 1'b0;
        end
    end
    
    // 计数器逻辑
    always @(posedge clk) begin
        if (en_pipe2) begin
            if (reset_counter)
                count <= 1;
            else
                count <= count + 1;
        end
    end
    
    // 前一个输入数据存储
    always @(posedge clk) begin
        if (en_pipe2 && reset_counter) begin
            prev <= din_reg;
        end
    end
    
    // 输出数据更新
    always @(posedge clk) begin
        if (en_pipe2 && update_output) begin
            dout <= {count, prev};
        end
    end
    
endmodule