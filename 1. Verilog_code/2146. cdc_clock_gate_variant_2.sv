//SystemVerilog
module cdc_clock_gate (
    input  wire src_clk,
    input  wire dst_clk,
    input  wire src_en,
    input  wire rst_n,
    output wire gated_dst_clk
);
    // 源时钟域寄存器
    reg src_en_stage1;
    
    // 源时钟域捕获使能信号
    always @(posedge src_clk or negedge rst_n) begin
        if (!rst_n)
            src_en_stage1 <= 1'b0;
        else
            src_en_stage1 <= src_en;
    end
    
    // CDC同步器寄存器
    reg meta_stage1, meta_stage2;
    reg sync_stage1, sync_stage2;
    
    // 两级同步器 - 扁平化处理亚稳态风险
    always @(posedge dst_clk or negedge rst_n) begin
        if (!rst_n) 
            meta_stage1 <= 1'b0;
        else 
            meta_stage1 <= src_en_stage1;
    end
    
    always @(posedge dst_clk or negedge rst_n) begin
        if (!rst_n) 
            meta_stage2 <= 1'b0;
        else 
            meta_stage2 <= meta_stage1;
    end
    
    // 额外同步级别 - 扁平化CDC可靠性逻辑
    always @(posedge dst_clk or negedge rst_n) begin
        if (!rst_n) 
            sync_stage1 <= 1'b0;
        else 
            sync_stage1 <= meta_stage2;
    end
    
    always @(posedge dst_clk or negedge rst_n) begin
        if (!rst_n) 
            sync_stage2 <= 1'b0;
        else 
            sync_stage2 <= sync_stage1;
    end
    
    // 时钟门控逻辑 - 改进时序控制
    assign gated_dst_clk = dst_clk & sync_stage2;
    
endmodule