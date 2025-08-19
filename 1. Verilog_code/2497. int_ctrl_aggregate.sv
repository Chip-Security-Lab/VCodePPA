module int_ctrl_aggregate #(
    parameter IN_NUM = 8,
    parameter OUT_NUM = 2
)(
    input [IN_NUM-1:0] intr_in,
    input [OUT_NUM*IN_NUM-1:0] prio_map_flat, // 修改为扁平化数组
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
    
    // 修改always_comb为always @*
    always @* begin
        integer i;
        intr_out = 0;
        for (i = 0; i < OUT_NUM; i = i + 1)
            intr_out[i] = |(intr_in & prio_map[i]);
    end
endmodule