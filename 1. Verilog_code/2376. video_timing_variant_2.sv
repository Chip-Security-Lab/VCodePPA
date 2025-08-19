//SystemVerilog
module video_timing #(parameter H_TOTAL=800)(
    input clk,
    output reg h_sync,
    output [9:0] h_count
);
    // 计数器和多级流水线寄存器
    reg [9:0] cnt;
    reg [9:0] cnt_stage1, cnt_stage2, cnt_stage3;
    reg h_sync_stage1, h_sync_stage2;
    
    // 多级流水线实现，分散驱动负载和计算复杂度
    always @(posedge clk) begin
        // 阶段0: 计数器逻辑
        cnt <= (cnt < H_TOTAL-1) ? cnt + 1 : 0;
        
        // 阶段1: 第一级流水线
        cnt_stage1 <= cnt;
        
        // 阶段2: 第二级流水线
        cnt_stage2 <= cnt_stage1;
        h_sync_stage1 <= (cnt_stage1 < 96) ? 0 : 1;
        
        // 阶段3: 第三级流水线
        cnt_stage3 <= cnt_stage2;
        h_sync_stage2 <= h_sync_stage1;
        
        // 阶段4: 最终输出寄存器
        h_sync <= h_sync_stage2;
    end
    
    // 使用流水线寄存器驱动输出
    assign h_count = cnt_stage3;
endmodule