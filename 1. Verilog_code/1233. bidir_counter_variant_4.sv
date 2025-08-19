//SystemVerilog
module bidir_counter #(parameter N = 4) (
    input wire clock, clear, load, up_down,
    input wire [N-1:0] data_in,
    output reg [N-1:0] count
);
    // 为不同功能使用单独的寄存器组
    reg load_reg, up_down_reg, clear_reg;
    reg [N-1:0] data_in_reg;
    
    // 拆分计算信号以平衡路径
    reg [N-1:0] increment_result, decrement_result;
    reg [N-1:0] next_count_value;
    
    // 输入信号寄存 - 并行处理以减少路径依赖
    always @(posedge clock) begin
        clear_reg <= clear;
        load_reg <= load;
        up_down_reg <= up_down;
        data_in_reg <= data_in;
    end
    
    // 预计算递增和递减结果 - 并行路径以降低关键路径延迟
    always @(*) begin
        increment_result = count + 1'b1;
        decrement_result = count - 1'b1;
        next_count_value = up_down_reg ? increment_result : decrement_result;
    end
    
    // 计数器状态更新逻辑 - 拆分条件以减少嵌套逻辑深度
    always @(posedge clock) begin
        if (clear_reg)
            count <= {N{1'b0}};
        else if (load_reg)
            count <= data_in_reg;
        else
            count <= next_count_value;
    end
endmodule