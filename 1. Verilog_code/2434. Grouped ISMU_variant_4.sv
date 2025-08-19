//SystemVerilog
module grouped_ismu(
    input clk, rstn,
    input [15:0] int_sources,
    input [3:0] group_mask,
    output reg [3:0] group_int
);
    wire [3:0] group0, group1, group2, group3;
    reg [3:0] group_active;
    reg [3:0] masked_interrupts;
    
    // 划分中断源到各组
    assign group0 = int_sources[3:0];
    assign group1 = int_sources[7:4];
    assign group2 = int_sources[11:8];
    assign group3 = int_sources[15:12];
    
    // 检测每组是否有任何中断激活
    always @(*) begin
        group_active[0] = |group0;
        group_active[1] = |group1;
        group_active[2] = |group2;
        group_active[3] = |group3;
    end
    
    // 应用掩码到激活的组
    always @(*) begin
        masked_interrupts[0] = ~group_mask[0] & group_active[0];
        masked_interrupts[1] = ~group_mask[1] & group_active[1];
        masked_interrupts[2] = ~group_mask[2] & group_active[2];
        masked_interrupts[3] = ~group_mask[3] & group_active[3];
    end
    
    // 更新输出寄存器
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            group_int <= 4'h0;
        end
        else begin
            group_int <= masked_interrupts;
        end
    end
endmodule