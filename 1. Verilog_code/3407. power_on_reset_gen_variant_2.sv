//SystemVerilog
module power_on_reset_gen(
    input wire clk,
    input wire power_stable,
    output reg por_reset_n
);
    // 寄存器定义
    reg power_stable_reg;
    reg power_stable_meta;    // 添加亚稳态防护寄存器
    reg [2:0] por_counter;
    reg reset_condition;
    reg reset_condition_pipe; // 添加流水线寄存器
    
    // 输入同步化与亚稳态防护 (两级同步器)
    always @(posedge clk) begin
        power_stable_meta <= power_stable;
        power_stable_reg <= power_stable_meta;
    end
    
    // 计数器逻辑 - 保持不变
    always @(posedge clk) begin
        if (!power_stable_reg)
            por_counter <= 3'b0;
        else if (por_counter < 3'b111)
            por_counter <= por_counter + 1'b1;
    end
    
    // 将复位条件计算分为两个流水线阶段
    // 第一阶段：计算复位条件
    always @(posedge clk) begin
        reset_condition <= !power_stable_reg || (por_counter < 3'b111);
    end
    
    // 第二阶段：流水线寄存器
    always @(posedge clk) begin
        reset_condition_pipe <= reset_condition;
    end
    
    // 输出逻辑 - 使用流水线寄存器的结果
    always @(posedge clk) begin
        por_reset_n <= !reset_condition_pipe;
    end
endmodule