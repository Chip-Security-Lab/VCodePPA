//SystemVerilog
module gray_clock_divider(
    input clock,
    input reset,
    output [3:0] gray_out
);
    // 流水线寄存器
    reg [3:0] count, count_stage1, count_stage2;
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // 第0级 - 初始P和G信号计算
    reg [3:0] p_stage0, g_stage0;
    
    // 第1级 - 流水线寄存器
    reg [3:0] p_stage1, g_stage1;
    
    // 第2级 - 流水线寄存器
    reg [3:0] carry_stage2;
    reg [3:0] next_count_stage2;
    
    // 流水线阶段1 - 初始P和G信号计算
    wire [3:0] p_wire = count | 4'b0001; // 传播信号
    wire [3:0] g_wire = count & 4'b0001; // 生成信号
    
    // 流水线阶段2 - 合并传播和生成
    wire [3:0] p_stage1_wire, g_stage1_wire;
    
    assign p_stage1_wire[0] = p_stage0[0];
    assign g_stage1_wire[0] = g_stage0[0];
    
    assign p_stage1_wire[1] = p_stage0[1] & p_stage0[0];
    assign g_stage1_wire[1] = g_stage0[1] | (p_stage0[1] & g_stage0[0]);
    
    assign p_stage1_wire[2] = p_stage0[2] & p_stage0[1];
    assign g_stage1_wire[2] = g_stage0[2] | (p_stage0[2] & g_stage0[1]);
    
    assign p_stage1_wire[3] = p_stage0[3] & p_stage0[2];
    assign g_stage1_wire[3] = g_stage0[3] | (p_stage0[3] & g_stage0[2]);
    
    // 流水线阶段3 - 计算最终进位和结果
    wire [3:0] carry_wire;
    wire [3:0] next_count_wire;
    
    assign carry_wire[0] = g_stage1[0];
    assign carry_wire[1] = g_stage1[1];
    assign carry_wire[2] = g_stage1[2] | (p_stage1[2] & g_stage1[0]);
    assign carry_wire[3] = g_stage1[3] | (p_stage1[3] & g_stage1[1]);
    
    assign next_count_wire[0] = p_stage1[0] ^ 1'b0;
    assign next_count_wire[1] = p_stage1[1] ^ carry_wire[0];
    assign next_count_wire[2] = p_stage1[2] ^ carry_wire[1];
    assign next_count_wire[3] = p_stage1[3] ^ carry_wire[2];
    
    // 格雷码转换
    wire [3:0] gray_out_wire = {count_stage2[3], 
                              count_stage2[3]^count_stage2[2], 
                              count_stage2[2]^count_stage2[1], 
                              count_stage2[1]^count_stage2[0]};
    
    // 流水线寄存器更新
    always @(posedge clock) begin
        if (reset) begin
            // 复位所有流水线寄存器
            count <= 4'b0000;
            p_stage0 <= 4'b0000;
            g_stage0 <= 4'b0000;
            p_stage1 <= 4'b0000;
            g_stage1 <= 4'b0000;
            carry_stage2 <= 4'b0000;
            next_count_stage2 <= 4'b0000;
            count_stage1 <= 4'b0000;
            count_stage2 <= 4'b0000;
            valid_stage1 <= 1'b0;
            valid_stage2 <= 1'b0;
            valid_stage3 <= 1'b0;
        end
        else begin
            // 阶段1 - 计算初始P和G信号
            p_stage0 <= p_wire;
            g_stage0 <= g_wire;
            count_stage1 <= count;
            valid_stage1 <= 1'b1;
            
            // 阶段2 - 更新P和G信号
            p_stage1 <= p_stage1_wire;
            g_stage1 <= g_stage1_wire;
            count_stage2 <= count_stage1;
            valid_stage2 <= valid_stage1;
            
            // 阶段3 - 计算最终结果
            carry_stage2 <= carry_wire;
            next_count_stage2 <= next_count_wire;
            valid_stage3 <= valid_stage2;
            
            // 更新计数器 - 仅当整个流水线计算完成后
            if (valid_stage3)
                count <= next_count_stage2;
        end
    end
    
    // 输出格雷码
    assign gray_out = gray_out_wire;
endmodule