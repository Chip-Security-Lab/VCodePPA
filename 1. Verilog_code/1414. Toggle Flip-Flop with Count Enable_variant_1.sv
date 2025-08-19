//SystemVerilog
module toggle_ff_count_enable (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       count_en,
    output reg  [3:0] q
);

    // 优化流水线寄存器结构
    reg        count_en_pipe1, count_en_pipe2;
    reg [3:0]  q_next;
    
    // 第一级流水线 - 同步输入信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_en_pipe1 <= 1'b0;
        end
        else begin
            count_en_pipe1 <= count_en;
        end
    end
    
    // 第二级流水线 - 同步使能信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_en_pipe2 <= 1'b0;
        end
        else begin
            count_en_pipe2 <= count_en_pipe1;
        end
    end
    
    // 计算下一个状态值 - 优化的组合逻辑
    // 将条件判断与计算分离，平衡路径延迟
    always @(*) begin
        q_next = q;
        if (count_en_pipe2) begin
            q_next = q + 1'b1;
        end
    end
    
    // 更新输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q <= 4'b0000;
        end
        else begin
            q <= q_next;
        end
    end

endmodule