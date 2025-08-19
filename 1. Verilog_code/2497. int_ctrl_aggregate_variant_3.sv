//SystemVerilog
module int_ctrl_aggregate #(
    parameter IN_NUM = 8,
    parameter OUT_NUM = 2
)(
    input [IN_NUM-1:0] intr_in,
    input [OUT_NUM*IN_NUM-1:0] prio_map_flat,
    output reg [OUT_NUM-1:0] intr_out
);
    // 提取prio_map数组
    wire [IN_NUM-1:0] prio_map [0:OUT_NUM-1];
    wire [OUT_NUM-1:0] masked_interrupts [0:IN_NUM-1];
    
    genvar g, h;
    generate
        // 解析prio_map扁平数组
        for (g = 0; g < OUT_NUM; g = g + 1) begin: prio_map_gen
            assign prio_map[g] = prio_map_flat[(g+1)*IN_NUM-1:g*IN_NUM];
        end
        
        // 预计算每个输入中断对每个输出的贡献
        for (g = 0; g < IN_NUM; g = g + 1) begin: intr_mask_gen
            for (h = 0; h < OUT_NUM; h = h + 1) begin: out_mask_gen
                assign masked_interrupts[g][h] = intr_in[g] & prio_map[h][g];
            end
        end
    endgenerate
    
    // 使用组合式逻辑优化中断聚合过程
    integer i, j;
    always @* begin
        intr_out = {OUT_NUM{1'b0}};
        
        // 优化的比较逻辑 - 从低位到高位扫描以减少关键路径
        for (j = 0; j < OUT_NUM; j = j + 1) begin
            for (i = 0; i < IN_NUM; i = i + 1) begin
                intr_out[j] = intr_out[j] | masked_interrupts[i][j];
            end
        end
    end
endmodule