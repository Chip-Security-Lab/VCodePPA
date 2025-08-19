//SystemVerilog
module variable_step_counter #(parameter STEP=1) (
    input clk, rst,
    output reg [7:0] ring_reg
);
    // 优化的流水线寄存器
    reg [7:0] ring_reg_next;
    
    // 提前计算位掩码，减少运行时逻辑层级
    localparam [7:0] LOWER_MASK = (1 << STEP) - 1;
    localparam [7:0] UPPER_MASK = ~LOWER_MASK;
    
    // 优化的组合逻辑，分解复杂操作
    wire [7:0] rotated_value;
    wire [7:0] lower_part, upper_part;
    
    // 使用掩码提取位，减少索引计算的复杂度
    assign lower_part = ring_reg & LOWER_MASK;
    assign upper_part = ring_reg & UPPER_MASK;
    
    // 使用移位操作代替位拼接，减少关键路径
    assign rotated_value = (upper_part >> STEP) | (lower_part << (8-STEP));
    
    // 流水线实现
    always @(posedge clk) begin
        if (rst) begin
            ring_reg_next <= 8'h01;
            ring_reg <= 8'h01;
        end
        else begin
            // 合并流水线阶段，减少数据路径长度
            ring_reg_next <= rotated_value;
            ring_reg <= ring_reg_next;
        end
    end
endmodule