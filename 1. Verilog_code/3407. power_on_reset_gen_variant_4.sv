//SystemVerilog
// 顶层模块：电源上电复位生成器
module power_on_reset_gen (
    input  wire clk,
    input  wire power_stable,
    output wire por_reset_n
);
    // 内部信号
    wire count_done;
    wire increment_en;
    
    // 子模块实例化
    por_counter_module counter_inst (
        .clk           (clk),
        .power_stable  (power_stable),
        .increment_en  (increment_en),
        .count_done    (count_done)
    );
    
    por_control_module control_inst (
        .clk           (clk),
        .power_stable  (power_stable),
        .count_done    (count_done),
        .increment_en  (increment_en),
        .por_reset_n   (por_reset_n)
    );
    
endmodule

// 子模块：计数器模块 - 已优化寄存器位置
module por_counter_module (
    input  wire clk,
    input  wire power_stable,
    input  wire increment_en,
    output wire count_done
);
    reg [2:0] por_counter_reg;
    wire [2:0] next_counter;
    
    // 计算下一个计数值的组合逻辑
    assign next_counter = increment_en ? (por_counter_reg + 3'b001) : por_counter_reg;
    
    // 计数完成信号
    assign count_done = &por_counter_reg;
    
    // 寄存器已移动到组合逻辑之后
    always @(posedge clk or negedge power_stable) begin
        if (!power_stable) begin
            por_counter_reg <= 3'b000;
        end else begin
            por_counter_reg <= next_counter;
        end
    end
endmodule

// 子模块：控制逻辑模块 - 已优化寄存器位置
module por_control_module (
    input  wire clk,
    input  wire power_stable,
    input  wire count_done,
    output reg  increment_en,
    output wire por_reset_n
);
    reg por_reset_reg;
    wire next_reset_n;
    
    // 移动增加使能到寄存器后面
    always @(posedge clk or negedge power_stable) begin
        if (!power_stable) begin
            increment_en <= 1'b1; // 复位时允许计数
        end else begin
            increment_en <= ~count_done; // 只在计数未完成时允许增加
        end
    end
    
    // 复位控制前向重定时
    assign next_reset_n = count_done;
    assign por_reset_n = por_reset_reg;
    
    // 复位寄存器逻辑
    always @(posedge clk or negedge power_stable) begin
        if (!power_stable) begin
            por_reset_reg <= 1'b0;
        end else begin
            por_reset_reg <= next_reset_n;
        end
    end
endmodule