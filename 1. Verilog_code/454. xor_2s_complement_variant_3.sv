//SystemVerilog
module xor_2s_complement (
    input wire clk,         // 系统时钟
    input wire rst_n,       // 异步复位，低电平有效
    input wire [3:0] data_in,  // 输入数据
    output reg [3:0] xor_out   // 输出结果
);

    // 内部信号定义
    reg [3:0] stage1_data;     // 第一级流水线寄存器
    
    // 优化后的组合逻辑计算 - 替换XOR运算为取反操作
    // 对于4位输入与全1进行XOR，等价于取反操作，此优化可减少逻辑面积
    
    // 流水线第一级 - 数据捕获，集成逻辑计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_data <= 4'b0000;
        end else begin
            stage1_data <= ~data_in; // 取反操作替代XOR，减少一个中间信号和路径延迟
        end
    end
    
    // 流水线第二级 - 输出寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            xor_out <= 4'b0000;
        end else begin
            // 增加使能条件以降低功耗 - 当数据变化时才更新
            if (stage1_data != xor_out)
                xor_out <= stage1_data;
        end
    end

endmodule