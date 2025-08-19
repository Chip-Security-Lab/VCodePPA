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
    genvar g;
    generate
        for (g = 0; g < OUT_NUM; g = g + 1) begin: prio_map_gen
            assign prio_map[g] = prio_map_flat[(g+1)*IN_NUM-1:g*IN_NUM];
        end
    endgenerate
    
    // 用带状进位加法器算法处理中断聚合逻辑
    always @* begin
        integer i;
        reg [IN_NUM-1:0] masked_intr;
        reg [IN_NUM-1:0] sum;
        reg [IN_NUM:0] carry;
        
        intr_out = 0;
        
        for (i = 0; i < OUT_NUM; i = i + 1) begin
            // 掩码中断输入
            masked_intr = intr_in & prio_map[i];
            
            // 使用带状进位加法器计算是否有中断
            carry[0] = 1'b0;
            
            // 带状进位加法器实现
            carry[1] = masked_intr[0] | (0 & carry[0]);
            carry[2] = masked_intr[1] | (masked_intr[1] & carry[1]);
            carry[3] = masked_intr[2] | (masked_intr[2] & carry[2]);
            carry[4] = masked_intr[3] | (masked_intr[3] & carry[3]);
            carry[5] = masked_intr[4] | (masked_intr[4] & carry[4]);
            carry[6] = masked_intr[5] | (masked_intr[5] & carry[5]);
            carry[7] = masked_intr[6] | (masked_intr[6] & carry[6]);
            carry[8] = masked_intr[7] | (masked_intr[7] & carry[7]);
            
            // 如果最终进位不为0，则表示有中断
            intr_out[i] = carry[IN_NUM];
        end
    end
endmodule