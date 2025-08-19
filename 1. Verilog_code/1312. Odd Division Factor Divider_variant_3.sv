//SystemVerilog
// 顶层模块
module odd_div #(parameter DIV = 3) (
    input  wire clk_i,
    input  wire reset_i,
    output wire clk_o
);
    // 内部信号
    wire [$clog2(DIV)-1:0] count_value;
    wire count_max_reached;
    
    // 子模块实例化
    counter_module #(
        .DIV(DIV)
    ) counter_inst (
        .clk_i           (clk_i),
        .reset_i         (reset_i),
        .count_value     (count_value),
        .count_max_reached(count_max_reached)
    );
    
    toggle_module toggle_inst (
        .clk_i           (clk_i),
        .reset_i         (reset_i),
        .toggle_enable   (count_max_reached),
        .clk_o           (clk_o)
    );
    
endmodule

// 计数器子模块
module counter_module #(parameter DIV = 3) (
    input  wire clk_i,
    input  wire reset_i,
    output wire [$clog2(DIV)-1:0] count_value,
    output reg  count_max_reached
);
    reg [$clog2(DIV)-1:0] count_next;
    reg [$clog2(DIV)-1:0] count_reg;
    
    // 计数器组合逻辑提前计算
    always @(*) begin
        if (count_reg == DIV - 1) begin
            count_next = 0;
        end else begin
            count_next = count_reg + 1'b1;
        end
    end
    
    // 寄存器移到组合逻辑之前
    always @(posedge clk_i) begin
        if (reset_i) begin
            count_reg <= 0;
            count_max_reached <= 1'b0;
        end else begin
            count_reg <= count_next;
            count_max_reached <= (count_reg == DIV - 2); // 提前一个周期检测
        end
    end
    
    // 输出逻辑
    assign count_value = count_reg;
endmodule

// 时钟切换子模块
module toggle_module (
    input  wire clk_i,
    input  wire reset_i,
    input  wire toggle_enable,
    output wire clk_o
);
    reg toggle_enable_reg;
    reg clk_reg;
    wire clk_next;
    
    // 移动寄存器到组合逻辑之前
    assign clk_next = toggle_enable_reg ? ~clk_reg : clk_reg;
    
    // 寄存化输入信号
    always @(posedge clk_i) begin
        if (reset_i) begin
            toggle_enable_reg <= 1'b0;
            clk_reg <= 1'b0;
        end else begin
            toggle_enable_reg <= toggle_enable;
            clk_reg <= clk_next;
        end
    end
    
    // 输出赋值
    assign clk_o = clk_reg;
endmodule